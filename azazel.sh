#!/bin/bash

# Adding some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

template=""  # Default template
rate_limit=""
proxy=""
target=""

help_message() {
    echo
    echo -e "Usage: $0 [./azazel.sh -d "https://target.com" -t ~/fuzzing-templates/ --nrl 5 --proxy http://127.0.0.1:8080]\n"
    echo "Options:"
    echo "  -d                 Specify the target domain"
    echo "  -t                 Use Nuclei with a specific template"
    echo "  --nrl              Set Nuclei rate limit (e.g., --nrl 10, default is 150)"
    echo "  --proxy            Set proxy for selected tools (e.g., --proxy http://127.0.0.1:8080)"
    echo "  -h                 Display this help message"
    echo
}

while :; do
    case $1 in
        -h|--help)
            help_message
            exit
            ;;
        -d)
            target="$2"
            shift
            ;;
        -t)
            template="$2"
            shift
            ;;
        --nrl)
            rate_limit="--rl $2"
            shift
            ;;
        --proxy)
            proxy="--proxy $2"
            shift
            ;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)
            break
    esac
    shift
done

if [ -z "$target" ]; then
    help_message
    exit 1
fi

timestamp=$(date '+%Y%m%d%H%M')
output_dir="scan/$target/$timestamp"
mkdir -p "$output_dir"

# Essentials Check
check_additional_info() {
    local target="$1"
    local output_dir="$2"
    
    echo

    # Use whatweb for detecting technologies 
    echo -e "${YELLOW}[+] Detecting Technologies on the target...${NC}"
    whatweb -a 1 "$target" --log-brief="$output_dir/whatweb.txt"

    echo
}

check_additional_info "$target" "$output_dir"

# Spidering part
echo -e "${YELLOW}[!] Executing paramspider, please wait...${NC}"
# Remove "http://" or "https://" and trailing slash from the URL
target_url=$(echo "$target" | sed -e 's#^https\?://##' -e 's#/$##')

# Run urls and parameters gathering
paramspider -d "$target_url"
mv "results/$target_url.txt" "$output_dir/full_urls.txt"
rm -rf results

echo 

echo -e "${YELLOW}Validating urls with httpx...${NC}"
httpx -l "$output_dir/full_urls.txt" -o "$output_dir/paramspider.txt" $proxy
rm -rf "$output_dir/full_urls.txt"

echo

echo -e "${YELLOW}Executing gau on the target${NC}"
~/go/bin/gau --blacklist png,jpg,gif $target_url $proxy | sort -u | tee -a "$output_dir/gau.txt"

echo

# Execute nuclei if the template is provided
if [ ! -z "$template" ]; then
    echo -e "${YELLOW}[!] Executing nuclei with template $template, please wait...${NC}"
    
    combined_output="$output_dir/nuclei_results.txt"
    nuclei -l "$file" -t "$template" $rate_limit $proxy >> "$combined_output"
fi

echo

echo -e "${GREEN}[+] Scan complete. Results saved in $output_dir${NC}"

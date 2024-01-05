#!/bin/bash

# Adding some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

template=""  # Default template
rate_limit=""
katana_rate_limit=""
proxy=""
target=""

help_message() {
    echo
    echo -e "Usage: $0 [./azazel.sh -d "https://target.com" -k --krl 2 -t ~/fuzzing-templates/ --nrl 5 --proxy http://127.0.0.1:8080]\n"
    echo "Options:"
    echo "  -p                 Use ParamSpider (default)"
    echo "  -k                 Use Katana"
    echo "  -d                 Specify the target domain"
    echo "  -t                 Use Nuclei with a specific template"
    echo "  --nrl              Set Nuclei rate limit (e.g., --nrl 10, default is 150)"
    echo "  --krl              Set Katana rate limit (e.g., --krl 10, default is 150)"
    echo "  --proxy            Set proxy for selected tools (e.g., --proxy http://127.0.0.1:8080)"
    echo "  -h                 Display this help message"
    echo -e "\nAvailable spider tools: paramspider, katana"
    echo
}

spider_tool="paramspider"  # Default spider tool

while :; do
    case $1 in
        -h|--help)
            help_message
            exit
            ;;
        -p)
            spider_tool="paramspider"
            ;;
        -k)
            spider_tool="katana"
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
        --krl)
            katana_rate_limit="--rl $2"
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

echo -e "${YELLOW}[!] Executing $spider_tool, please wait...${NC}"

if [ "$spider_tool" == "paramspider" ]; then
    # Run ParamSpider
    paramspider -d "$target"
    mv "results/$target.txt" "$output_dir/full_urls.txt"
    rm -rf results

    echo 

    echo -e "${YELLOW}Validating urls with httpx...${NC}"
    httpx -l "$output_dir/full_urls.txt" -mc 200 | grep .js | tee "$output_dir/js.txt"
    rm -rf "$output_dir/full_urls.txt"
elif [ "$spider_tool" == "katana" ]; then
    # Run Katana
    katana -u "$target" -d 10 -jsl -kf all -jc -iqp -aff -fx -o "$output_dir/urls.txt" $katana_rate_limit $proxy &
    wait
    cat "$output_dir/urls.txt" | httpx -mc 200 | grep .js | tee "$output_dir/js.txt"
else
    echo "Invalid spider tool: $spider_tool"
    exit 1
fi

# Grep for sensitive data
echo -e "${YELLOW}[+] Searching for sensitive data in JavaScript files...${NC}"
grep -r -E "aws_access_key|aws_secret_key|api key|passwd|pwd|heroku|slack|firebase|swagger|aws_secret_key|aws key|password|ftp password|jdbc|db|sql|secret jet|config|admin|pwd|json|gcp|htaccess|.env|ssh key|.git|access key|secret token|oauth_token|oauth_token_secret" "$output_dir/js.txt" > "$output_dir/sensitive_data.txt"

# Nuclei scan on JavaScript files
echo -e "${YELLOW}[+] Executing Nuclei on JavaScript files...${NC}"
nuclei -l "$output_dir/js.txt" -t ~/nuclei-templates/exposures/ -o "$output_dir/js_exposures_results.txt"

echo

echo -e "${GREEN}[+] Scan complete. Results saved in $output_dir${NC}"

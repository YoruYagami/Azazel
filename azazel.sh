#!/bin/bash

# Adding some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'

template=""
rate_limit="--rl 50" # Default to medium rate limit
proxy=""
target=""
fuzz_enabled=0
fuzz_template_path="~/fuzzing-templates" # Default path

help_message() {
    echo
    echo -e "Usage: $0 [./azazel.sh -d \"https://target.com\" --rl 15 -t ~/fuzzing-templates/ --proxy http://127.0.0.1:8080 --slow/--medium/--fast --fuzz [template path]]\n"
    echo "Options:"
    echo "  -d                 Specify the target domain"
    echo "  -t                 Use Nuclei with a specific template"
    echo "  --rl               Set global rate limit (e.g., --rl 15)"
    echo "  --proxy            Set proxy for selected tools (e.g., --proxy http://127.0.0.1:8080)"
    echo "  --slow             Set rate limit for slow scanning"
    echo "  --medium           Set rate limit for medium scanning (default)"
    echo "  --fast             Set rate limit for fast scanning"
    echo "  --fuzz             Enable fuzzing with Dalfox and Nuclei using specified template path"
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
        --slow)
            rate_limit="--rl 5"
            ;;
        --medium)
            rate_limit="--rl 50"
            ;;
        --fast)
            rate_limit="--rl 150"
            ;;
        --proxy)
            proxy="--proxy $2"
            shift
            ;;
        --fuzz)
            fuzz_enabled=1
            if [ ! -z "$2" ] && [ "${2:0:1}" != "-" ]; then
                fuzz_template_path="$2"
                shift
            fi
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

# Running whatweb
echo -e "${YELLOW}[!] Executing whatweb...${NC}"
whatweb "$target" | tee "$output_dir/whatweb.txt"
sleep 2
echo

# Running wafw00f
echo -e "${YELLOW}[!] Executing wafw00f...${NC}"
wafw00f "$target" | tee "$output_dir/wafw00f.txt"
sleep 2
echo

# Checking for X-Frame-Options header
echo -e "${YELLOW}[!] Checking for X-Frame-Options header...${NC}"
if ! curl -s -I "$target" | grep -qi "X-Frame-Options"; then
    echo -e "${RED}[-] X-Frame-Options header missing. Creating ClickJacking PoC...${NC}"
    echo "<html><head><title>ClickJacking PoC</title></head><body>ClickJacking PoC<h2>Your Web Application Can be Mounted within an iFrame which makes it vulnerable to ClickJacking!</h2><iframe src=\"$target\" height=\"450\" width=\"1000\"></iframe></body></html>" > "$output_dir/clickjacking.html"
    firefox "$output_dir/clickjacking.html" &
else
    echo -e "${GREEN}[+] X-Frame-Options header present.${NC}"
fi
sleep 2
echo

echo -e "${YELLOW}[!] Executing katana, please wait...${NC}"
katana -u "$target" -d 5 -kf robotstxt,sitemapxml -o "$output_dir/urls.txt" $rate_limit $proxy
sleep 2
echo

# Execute Gobuster
echo -e "${YELLOW}[!] Executing Gobuster, please wait...${NC}"
gobuster dir -u "$target" -w /usr/share/seclists/Discovery/Web-Content/common.txt -o "$output_dir/gobuster_results.txt" $proxy
sleep 2
echo

# Execute Dalfox
if [ $fuzz_enabled -eq 1 ]; then
    echo -e "${YELLOW}[!] Executing Dalfox with fuzzing, please wait...${NC}"
    dalfox file "$output_dir/urls.txt" --mining-dom --deep-domxss --mining-dict --delay 500 --report $proxy -o "$output_dir/dalfox_fuzz_results.txt"
    sleep 2
    echo
fi

# Execute nuclei if the template is provided
if [ ! -z "$template" ] || [ $fuzz_enabled -eq 1 ]; then
    echo -e "${YELLOW}[!] Executing nuclei with template $template, please wait...${NC}"
    if [ $fuzz_enabled -eq 1 ]; then
        nuclei -l "$output_dir/urls.txt" -t "$fuzz_template_path" $rate_limit $proxy -as -o "$output_dir/nuclei_fuzz_results.txt"
    else
        nuclei -u "$target" -t "$template" $rate_limit $proxy -as -o "$output_dir/nuclei_results.txt"
    fi
    echo
fi

echo -e "${GREEN}[+] Scan complete. Results saved in $output_dir${NC}"
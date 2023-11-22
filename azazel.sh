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
wordlist="/usr/share/seclists/Discovery/Web-Content/common.txt" # Default wordlist

help_message() {
    echo
    echo -e "Usage: $0 [./azazel.sh -d \"https://target.com\" -w /path/to/wordlist --rl [rate limit] -t ~/fuzzing-templates/ --proxy http://127.0.0.1:8080 --fuzz [template path]]\n"
    echo "Options:"
    echo "  -d                 Specify the target domain"
    echo "  -w                 Specify the wordlist for Gobuster (default is common.txt)"
    echo "  -t                 Use Nuclei with a specific template"
    echo "  --rl               Set global rate limit (e.g., --rl 10)"
    echo "  --proxy            Set proxy for selected tools (e.g., --proxy http://127.0.0.1:8080)"
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
        -w)
            wordlist="$2"
            shift
            ;;
        -t)
            template="$2"
            shift
            ;;
        --rl)
            rate_limit="--rl $2"
            shift
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
wait
echo

# Running wafw00f
echo -e "${YELLOW}[!] Executing wafw00f...${NC}"
wafw00f "$target" | tee "$output_dir/wafw00f.txt"
wait
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
wait
echo

# Execute Heartbleed check
echo -e "${YELLOW}[!] Checking for Heartbleed vulnerability...${NC}"
echo "QUIT" | openssl s_client -connect $target:443 2>&1 | grep 'server extension "heartbeat" (id=15)' || echo "$target: safe"
wait
echo

# Execute Katana
echo -e "${YELLOW}[!] Executing Katana and JS analysis, please wait...${NC}"
katana -u "$target" -depth 10 -jc -jsl -kf all -timeout 20 -retry 5 -s depth-first -iqp -c 30 -p 30 -aff -fx -o "$output_dir/urls.txt" $rate_limit $proxy
wait
echo

# Extract JS and URLs from JS
getJS --url $target --output "$output_dir/javascript_results.txt"
if [ -s "$output_dir/javascript_results.txt" ]; then
    while IFS= read -r js_file; do
        curl "$js_file" | grep -Eo "(http|https)://[a-zA-Z0-9./?=_-]*" >> "$output_dir/js_urls.txt"
    done < "$output_dir/javascript_results.txt"
fi
wait
echo

# Check for SSL and set Gobuster flag
ssl_check=$(curl -Is $target | grep -i 'Location: https')
gobuster_tls=""
if [ -z "$ssl_check" ]; then
    gobuster_tls="-k"
fi

# Execute Gobuster
echo -e "${YELLOW}[!] Executing Gobuster, please wait...${NC}"
gobuster dir -u "$target" -w "$wordlist" --quiet -x php,html,js,txt -t 20 -r -f -e -s 200,204,301,302,307,401,403 -b 404 --random-agent --retry --retry-attempts 5 -o "$output_dir/gobuster_results.txt" $proxy
wait
echo

# Execute Dalfox
echo -e "${YELLOW}[!] Executing Dalfox, please wait...${NC}"
if [ $fuzz_enabled -eq 1 ]; then
    grep -E "\?" "$output_dir/urls.txt" > "$output_dir/urls_with_params.txt"
    dalfox file "$output_dir/urls_with_params.txt" --mining-dom --deep-domxss --mining-dict-word --mining-dom --remote-wordlists --mining-dict --waf-evasion --follow-redirects --ignore-return 404,500 --silence $proxy -o "$output_dir/dalfox_fuzz_results.txt"
else
    dalfox url "$target" --mining-dom --deep-domxss --mining-dict-word --mining-dom --remote-wordlists --mining-dict --waf-evasion --follow-redirects --ignore-return 404,500 --silence --report $proxy -o "$output_dir/dalfox_results.txt"
fi
wait
echo

# Execute nuclei if the template is provided
echo -e "${YELLOW}[!] Executing nuclei, please wait...${NC}"
if [ ! -z "$template" ] || [ $fuzz_enabled -eq 1 ]; then
    if [ $fuzz_enabled -eq 1 ]; then
        nuclei -l "$output_dir/urls.txt" -t "$fuzz_template_path" $rate_limit $proxy -as -o "$output_dir/nuclei_fuzz_results.txt"
    else
        nuclei -u "$target" -t "$template" $rate_limit $proxy -as -o "$output_dir/nuclei_results.txt"
    fi
fi
echo

echo -e "${GREEN}[+] Scan complete. Results saved in $output_dir${NC}"

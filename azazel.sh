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
use_openredirex=0  # Default: don't use openredirex

help_message() {
    echo
    echo -e "Usage: $0 [./azazel.sh -d "https://target.com" -k --krl 2 -t ~/fuzzing-templates/ --nrl 5 --proxy http://127.0.0.1:8080 --openredirex]\n"
    echo "Options:"
    echo "  -p                 Use ParamSpider (default)"
    echo "  -k                 Use Katana"
    echo "  -d                 Specify the target domain"
    echo "  -t                 Use Nuclei with a specific template"
    echo "  --nrl              Set Nuclei rate limit (e.g., --nrl 10, default is 150)"
    echo "  --krl              Set Katana rate limit (e.g., --krl 10, default is 150)"
    echo "  --proxy            Set proxy for selected tools (e.g., --proxy http://127.0.0.1:8080)"
    echo "  --openredirex      Use openredirex on validated urls"
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
        --openredirex)
            use_openredirex=1
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
    declare -a source_code_endpoints=("/git" "/svn" "/hg" "/bzr" "/_darcs" "/Bitkeeper")

    echo

    # Use whatweb for detecting technologies 
    echo -e "${YELLOW}[+] Detecting Technologies on the target...${NC}"
    whatweb -a 1 "$target" --log-brief="$output_dir/whatweb.txt"

    echo

    # Check for Exposed Source Code
    echo -e "${YELLOW}[+] Checking for Common Exposed Source Code Endpoints...${NC}"
    for endpoint in "${source_code_endpoints[@]}"; do
        check_endpoint "$target" "$endpoint" "$output_dir"
        sleep 1
    done

    echo

    echo -e "${YELLOW}[+] Checking for headers${NC}"

    # Check X-Frame-Options header
    response_headers=$(curl -s -I "$target")
    header_value=$(echo "$response_headers" | grep -i "X-Frame-Options:" | awk -F: '{print $2}' | tr -d '[:space:]')

    if [[ -z $header_value ]]; then
        echo -e "${GREEN}[+] Target might be vulnerable to Clickjacking as X-Frame-Options header is missing!${NC}"
    else
        case "$header_value" in
            DENY)
                echo -e "${RED}[+] Anti-clickjacking X-Frame-Options header detected: DENY${NC}"
                ;;
            SAMEORIGIN)
                echo -e "${RED}[+] Anti-clickjacking X-Frame-Options header detected: SAMEORIGIN${NC}"
                ;;
            ALLOW-FROM*)
                echo -e "${RED}[+] Anti-clickjacking X-Frame-Options header detected: $header_value${NC}"
                ;;
            *)
                echo -e "${YELLOW}[?] Unrecognized X-Frame-Options header value: $header_value${NC}"
                ;;
        esac
    fi

    # Check for HttpOnly flag
    cookie_header=$(curl -s -I "$target" | grep -i "Set-Cookie")
    if [[ $cookie_header == *"; HttpOnly"* ]]; then
        echo -e "${RED}[-] HttpOnly flag is set on the cookie.${NC}"
    else
        echo -e "${GREEN}[+] HttpOnly flag is missing from the cookie!.${NC}"
    fi

    # Check for Content-Security-Policy (CSP) header
    csp_header=$(curl -s -I "$target" | grep -i "Content-Security-Policy")
    if [[ -z $csp_header ]]; then
        echo -e "${GREEN}[+] Content-Security-Policy (CSP) header is missing!.${NC}"
    else
        if [[ $csp_header == *'unsafe-inline'* ]] || [[ $csp_header == *'unsafe-eval'* ]]; then
            echo -e "${GREEN}[+] CSP contains unsafe directives (unsafe-inline or unsafe-eval).${NC}"
        else
            echo -e "${RED}[-] Proper CSP header detected.${NC}"
        fi
    fi

    echo
}

check_endpoint() {
    local target="$1"
    local endpoint="$2"
    local output_dir="$3"

    response=$(curl -s -o /dev/null -w "%{http_code}" "$target$endpoint")
    if [[ $response -eq 200 ]]; then
        echo -e "${GREEN}[+] $endpoint found. Saving...${NC}"
        content=$(curl -s "$target$endpoint")
        echo "$content" > "$output_dir$endpoint"
    else
        echo -e "${RED}[-] $endpoint not found.${NC}"
    fi
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
    httpx -l "$output_dir/full_urls.txt" -o "$output_dir/urls.txt"
    rm -rf "$output_dir/full_urls.txt"
elif [ "$spider_tool" == "katana" ]; then
    # Run Katana
    katana -u "$target" -d 5 -kf robotstxt,sitemapxml -o "$output_dir/urls.txt" $katana_rate_limit $proxy &
else
    echo "Invalid spider tool: $spider_tool"
    exit 1
fi

if [ $use_openredirex -eq 1 ]; then
    echo -e "${YELLOW}Filtering urls with 'gf redirect'...${NC}"
    gf redirect < "$output_dir/urls.txt" > "$output_dir/redirect_urls.txt"

    echo -e "${YELLOW}Using openredirex on filtered urls...${NC}"
    cat "$output_dir/redirect_urls.txt" | openredirex > "$output_dir/openredirex_results.txt"
    rm -rf "$output_dir/redirect_urls.txt"
fi

wait

# Add some space for better formatting
echo

# Display discovered vulnerabilities in a table-like format
echo -e "${YELLOW}Count of potential vulnerable URLs discovered:${NC}"
echo
printf "%-15s %-25s\n" "Vulnerability" "URLs discovered"
printf "%-15s %-25s\n" "-------------" "---------------"

# Use gf to find common patterns
mkdir -p "$output_dir/paramspider/vuln"
patterns=("lfi" "rce" "redirect" "sqli" "ssrf" "ssti" "xss" "idor" "debug_logic")

for pattern in "${patterns[@]}"; do
    matched_lines=$(gf "$pattern" < "$output_dir/urls.txt")
    if [ ! -z "$matched_lines" ]; then
        echo "$matched_lines" > "$output_dir/paramspider/vuln/gf_${pattern}.txt"
        count=$(echo "$matched_lines" | wc -l)
        printf "%-15s %-25s\n" "$pattern" "$count"
    fi
done

# Execute nuclei if the template is provided
if [ ! -z "$template" ]; then
    echo -e "${YELLOW}[!] Executing nuclei with template $template, please wait...${NC}"
    
    combined_output="$output_dir/nuclei_results.txt"

    for file in $output_dir/paramspider/vuln/*.txt; do
        pattern_name=$(basename "$file" .txt | sed 's/gf_//')

        # Here, using >> instead of > ensures appending instead of overwriting
        nuclei -l "$file" -t "$template" $rate_limit $proxy >> "$combined_output"
    done
fi

# Add some space for better formatting
echo

echo -e "${GREEN}[+] Scan complete. Results saved in $output_dir${NC}"

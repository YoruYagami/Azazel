#!/bin/bash

template=""  # Default template
rate_limit=""
spider_tool="paramspider"  # Default spider tool
katana_rate_limit=""
proxy=""
nikto_scan=false
target=""

help_message() {
    echo
    echo -e "Usage: $0 [./azazel.sh -d "https://target.com" -k --krl 2 -t ~/fuzzing-templates/ --nrl 5 --proxy http://127.0.0.1:8080]\n"
    echo "Options:"
    echo "  -p                 Use ParamSpider (default)"
    echo "  -k                 Use Katana"
    echo "  -n                 Perform an initial scan with Nikto"
    echo "  -d                 Specify the target domain"
    echo "  -t                 Use Nuclei with a specific template"
    echo "  --nrl              Set Nuclei rate limit (e.g., --nrl 10, default is 150)"
    echo "  --krl              Set Katana rate limit (e.g., --krl 10, default is 150)"
    echo "  --proxy            Set proxy for selected tools (e.g., --proxy http://127.0.0.1:8080)"
    echo "  -h                 Display this help message"
    echo -e "\nAvailable spider tools: paramspider, katana"
    echo
}

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
        -n)
            nikto_scan=true
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

# Function to display colored messages
color_echo() {
    local color="$1"
    shift
    echo -e "\033[${color}m$@\033[0m"
}

# Essentials Check
check_additional_info() {
    local target="$1"
    local output_dir="$2"

    echo

    # Check /robots.txt
    response=$(curl -s -o /dev/null -w "%{http_code}" "$target/robots.txt")
    if [[ $response -eq 200 ]]; then
        color_echo 32 "[+] /robots.txt found. Saving..."
        echo
        # Get and display the content of robots.txt
        robots_content=$(curl -s "$target/robots.txt")
        echo "$robots_content"
        echo "$robots_content" > "$output_dir/robots.txt"
    else
        color_echo 31 "[-] /robots.txt not found."
    fi

    echo

    # Check /sitemap.xml
    response=$(curl -s -o /dev/null -w "%{http_code}" "$target/sitemap.xml")
    if [[ $response -eq 200 ]]; then
        color_echo 32 "[+] /sitemap.xml found. Saving..."
        
        # Save the content of sitemap.xml without displaying on the terminal
        sitemap_content=$(curl -s "$target/sitemap.xml")
        echo "$sitemap_content" > "$output_dir/sitemap.xml"
    else
        color_echo 31 "[-] /sitemap.xml not found."
    fi

    echo

    # Check X-Frame-Options header
    header=$(curl -s -I "$target" | grep -i "X-Frame-Options")
    if [[ -z $header ]]; then
        color_echo 31 "[-] Target vulnerable to Clickjacking!."
    else
        color_echo 32 "[+] Anti-clickjacking X-Frame-Options header detected."
    fi

    echo

    # Check for HttpOnly flag
    cookie_header=$(curl -s -I "$target" | grep -i "Set-Cookie")
    if [[ $cookie_header == *"; HttpOnly"* ]]; then
        color_echo 32 "[+] HttpOnly flag is set on the cookie."
    else
        color_echo 31 "[-] HttpOnly flag is missing from the cookie!."
    fi

    echo

    # Check for Content-Security-Policy (CSP) header
    csp_header=$(curl -s -I "$target" | grep -i "Content-Security-Policy")
    if [[ -z $csp_header ]]; then
        color_echo 31 "[-] Content-Security-Policy (CSP) header is missing!."
    else
        if [[ $csp_header == *'unsafe-inline'* ]] || [[ $csp_header == *'unsafe-eval'* ]]; then
            color_echo 31 "[+] CSP contains unsafe directives (unsafe-inline or unsafe-eval)."
        else
            color_echo 32 "[-] Proper CSP header detected."
        fi
    fi

    echo
}

check_additional_info "$target" "$output_dir"

# If nikto_scan is true, run Nikto
if $nikto_scan; then
    color_echo 33 "[ ! ] Executing Nikto scan, please wait..."
    if [ -z "$proxy" ]; then
        nikto -host "$target" -o "$output_dir/nikto_output.txt"
    else
        nikto_proxy=$(echo $proxy | sed 's/--proxy //')
        nikto -host "$target" -useproxy "$nikto_proxy" -o "$output_dir/nikto_output.txt"
    fi
    echo
fi

color_echo 33 "[ ! ] Executing $spider_tool, please wait..."

if [ "$spider_tool" == "paramspider" ]; then
    # Run ParamSpider
    python3 ~/ParamSpider/paramspider.py -d "$target" --level high --quiet -o "$output_dir/urls.txt"
elif [ "$spider_tool" == "katana" ]; then
    # Run Katana
    katana -u "$target" -d 5 -kf robotstxt,sitemapxml -o "$output_dir/urls.txt" $katana_rate_limit $proxy &
else
    echo "Invalid spider tool: $spider_tool"
    exit 1
fi

# Run getJS
getJS_output="$output_dir/getjs_output.txt"
getJS --url "$target" --complete > "$getJS_output"

wait

# Add some space for better formatting
echo

# Display discovered vulnerabilities in a table-like format
color_echo 32 "Count of potential vulnerable URLs discovered:"
echo ""
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

# Count the number of JS files discovered
js_count=$(grep -Eo 'https?://[^/]+/[^ ]+\.js' "$getJS_output" | wc -l)
echo
color_echo 32 "JavaScript files discovered: $js_count"
echo

# Execute nuclei if the template is provided
if [ ! -z "$template" ]; then
    color_echo 33 "[ ! ] Executing nuclei with template $template, please wait..."
    
    for file in $output_dir/paramspider/vuln/*.txt; do
        nuclei -l "$file" -t "$template" $rate_limit $proxy -o "$output_dir/nuclei_results.txt"
    done
fi

# Add some space for better formatting
echo

color_echo 32 "[+] Scan complete. Results saved in $output_dir"

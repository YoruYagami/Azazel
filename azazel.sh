#!/bin/bash

# Help message
help_message() {
    echo -e "Usage: $0 [-p|-k] <target_domain>\n"
    echo "Options:"
    echo "  -p   Use ParamSpider (default)"
    echo "  -k   Use Katana"
    echo "  -h   Display this help message"
    echo -e "\nAvailable spider tools: paramspider, katana"
}

spider_tool="paramspider"  # Default spider tool

while getopts ":pkh" opt; do
  case $opt in
    p) spider_tool="paramspider" ;;
    k) spider_tool="katana" ;;
    h) help_message
       exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2
        help_message
        exit 1 ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -ne 1 ]; then
    help_message
    exit 1
fi

target="$1"
timestamp=$(date '+%Y%m%d%H%M')
output_dir="scan/$target/$timestamp"
mkdir -p "$output_dir"

# Function to display colored messages
color_echo() {
    local color="$1"
    shift
    echo -e "\033[${color}m$@\033[0m"
}

echo ""
color_echo 33 "[ ! ] Executing $spider_tool, please wait..."

if [ "$spider_tool" == "paramspider" ]; then
    # Run ParamSpider
    python3 ~/ParamSpider/paramspider.py -d "$target" --level high --quiet -o "$output_dir/parameter.txt"
elif [ "$spider_tool" == "katana" ]; then
    # Run Katana
    katana -u "$target" -o "$output_dir/parameter.txt" &
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
    matched_lines=$(gf "$pattern" < "$output_dir/parameter.txt")
    if [ ! -z "$matched_lines" ]; then
        echo "$matched_lines" > "$output_dir/paramspider/vuln/gf_${pattern}.txt"
        count=$(echo "$matched_lines" | wc -l)
        printf "%-15s %-25s\n" "$pattern" "$count"
    fi
done

# Count the number of JS files discovered
js_count=$(grep -Eo 'https?://[^/]+/[^ ]+\.js' "$getJS_output" | wc -l)
echo ""
color_echo 32 "JavaScript files discovered: $js_count"

# Add some space for better formatting
echo

color_echo 32 "[+] Scan complete. Results saved in $output_dir"

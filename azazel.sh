#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function to display help
usage() {
    echo -e "${YELLOW}=================== ${GREEN}Script Usage${YELLOW} ===================${NC}"
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 -f <domain_file> [--loop <loop_time>] [-o <output_file>] [-x <exclude_file>]\n"
    
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  ${GREEN}-f, --file${NC}    ${BLUE}Domain file to process${NC}"
    echo -e "  ${GREEN}--loop${NC}       ${BLUE}Time in seconds to wait before re-running the script${NC} ${RED}(default: 7200)${NC}"
    echo -e "  ${GREEN}-o, --output${NC}  ${BLUE}Output file for results${NC} ${RED}(default: subdomains.txt)${NC}"
    echo -e "  ${GREEN}-x, --exclude${NC} ${BLUE}File with subdomains to exclude from results${NC}\n"
    echo -e "${YELLOW}=================================================${NC}"
    exit 1
}

domain_file=""
loop_time=7200
output_file="subdomains.txt"
exclude_file=""

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                domain_file="$2"
                shift 2
                ;;
            --loop)
                loop_time="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -x|--exclude)
                exclude_file="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}Unknown option:${NC} $1"
                usage
                ;;
        esac
    done
}

# Parse command line arguments
parse_arguments "$@"

# Check if domain file is provided
if [[ -z "$domain_file" ]]; then
    echo -e "${RED}Error:${NC} You must provide a domain file"
    usage
fi

# Read domains from the file
readarray -t targets < "$domain_file"

while :
do
    for target in "${targets[@]}"
    do
        subfinder -d "$target" -o "$output_file"
    done

    cat "$output_file" | anew old_subdomains.txt | httpx -silent | notify -p telegram -id bot_name "New subdomains found for ${targets>
    > "$output_file"  # Clear the temporary file for new subdomains
    sleep "$loop_time"  # Wait for the specified time before running the loop again
done

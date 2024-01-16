#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function to display help
usage() {
    echo -e "${YELLOW}=================== ${GREEN}Script Help${YELLOW} ===================${NC}"
    echo -e "${BLUE}Description:${NC}"
    echo -e "  This script automates the process of finding and analyzing subdomains."
    echo -e "  It integrates various tools for subdomain discovery, port scanning, and reporting."

    echo

    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 -f <domain_file> [options]\n"
    
    echo -e "${BLUE}Options:${NC}"
    echo -e "  ${GREEN}-f, --file${NC}        ${BLUE}Specify domain file to process${NC}"
    echo -e "  ${GREEN}--loop${NC}           ${BLUE}Time in seconds to wait before re-running (default: 3600)${NC}"
    echo -e "  ${GREEN}-o, --output${NC}      ${BLUE}Specify output file for results (default: subdomains.txt)${NC}"
    echo -e "  ${GREEN}-x, --exclude${NC}     ${BLUE}File with subdomains to exclude${NC}"
    echo -e "  ${GREEN}--silent${NC}         ${BLUE}Run in silent mode${NC}"
    echo -e "  ${GREEN}--notify${NC}         ${BLUE}Enable notifications for new subdomains${NC}"
    echo -e "  ${GREEN}-n, --nuclei${NC}      ${BLUE}Run nuclei against new subdomains${NC}"
    echo -e "  ${GREEN}-t, --template${NC}    ${BLUE}Nuclei templates path (default: ~/nuclei-templates)${NC}"

    echo

    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 -f domains.txt --loop 3600 --output results.txt"
    echo -e "  $0 -f domains.txt --silent --notify --nuclei -t ~/nuclei-templates\n"

    echo -e "${YELLOW}=================================================${NC}"
    exit 1
}

domain_file=""
loop_time=3600
output_file="output.txt"
exclude_file=""
silent_mode=""
notify_mode=false
nuclei_mode=false
template_path=~/nuclei-templates

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
            --notify)
                notify_mode=true
                shift
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -x|--exclude)
                exclude_file="$2"
                shift 2
                ;;
            --silent)
                silent_mode="-silent"
                shift
                ;;
            -n|--nuclei)
                nuclei_mode=true
                shift
                ;;
            -t|--template)
                template_path="$2"
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

while :
do
    # Using assetfinder to find subdomains and output to sub1
    cat "$domain_file" | assetfinder -subs-only > sub1

    # Using findomain to find subdomains and output to sub2
    findomain -q -f "$domain_file" > sub2

    # Using subfinder to find subdomains and output to sub3
    subfinder -dL "$domain_file" -o sub3 -all -nW $silent_mode

    # Combining outputs from all tools, sort them uniquely, and store in output file
    cat sub1 sub2 sub3 | sort -u > "$output_file"

    # Clean up temporary files
    rm -rf sub1 sub2 sub3

    # Exclude subdomains listed in the exclude file if provided
    if [[ -n "$exclude_file" ]]; then
        grep -v -f "$exclude_file" "$output_file" > temp.txt
        mv temp.txt "$output_file"
    fi

    # Process new subdomains with anew and store them in a temporary file
    cat "$output_file" | anew subdomains.txt > new_subdomains.txt

    # Count the number of subdomains found
    echo "Number of new subdomains found: $(wc -l < new_subdomains.txt)"

    # Process with httpx and optionally notify
    cat new_subdomains.txt | httpx $silent_mode -status-code -tech-detect -title | if $notify_mode; then notify $silent_mode; fi
    
    # Run nuclei on the new subdomains if nuclei_mode is true
    if $nuclei_mode; then
        nuclei -l new_subdomains.txt -t "$template_path" -o nuclei_output.txt --silent | notify $silent_mode
    fi

    # Clear the output file for the next iteration
    > "$output_file"

    # Wait for specified loop time before next iteration
    sleep "$loop_time" 
done

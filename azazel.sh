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
    echo -e "  $0 -f <domain_file> [--loop <loop_time>] [-o <output_file>] [-x <exclude_file>] [--silent]\n"
    
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  ${GREEN}-f, --file${NC}    ${BLUE}Domain file to process${NC}"
    echo -e "  ${GREEN}--loop${NC}       ${BLUE}Time in seconds to wait before re-running the script${NC} ${RED}(default: 7200)${NC}"
    echo -e "  ${GREEN}-o, --output${NC}  ${BLUE}Output file for results${NC} ${RED}(default: subdomains.txt)${NC}"
    echo -e "  ${GREEN}-x, --exclude${NC} ${BLUE}File with subdomains to exclude from results${NC}"
    echo -e "  ${GREEN}--silent${NC}     ${BLUE}Run subfinder, httpx, and notify in silent mode${NC}"
    echo -e "  ${GREEN}-n, --nuclei${NC}     ${BLUE}Run nuclei against newly discovered live subdomains${NC}"
    echo -e "  ${GREEN}-t, --template${NC}     ${BLUE}Path to nuclei templates${NC} ${RED}(default: ~/nuclei-templates)${NC}\n"
    echo -e "${YELLOW}=================================================${NC}"
    exit 1
}

domain_file=""
loop_time=7200
output_file="output.txt"
exclude_file=""
silent_mode=""
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
    assetfinder -subs-only < "$domain_file" > sub1

    # Using findomain to find subdomains and output to sub2
    findomain -q -f "$domain_file" > sub2

    # Using subfinder to find subdomains and output to sub3
    subfinder -dL "$domain_file" -o sub3 -all -nW $silent_mode

    # Combining outputs from all tools, sort them uniquely, and store in output file
    cat sub1 sub2 sub3 | sort -u > "$output_file"

    # Exclude subdomains listed in the exclude file if provided
    if [[ -n "$exclude_file" ]]; then
        grep -v -f "$exclude_file" < "$output_file" > temp.txt
        mv temp.txt "$output_file"
    fi

    # Process new subdomains with anew and store them in a temporary file
    anew < "$output_file" subdomains.txt > new_subdomains.txt

    # Process with httpx and notify
    httpx $silent_mode -status-code -tech-detect -title < new_subdomains.txt | notify $silent_mode

    # Run naabu on the new subdomains
    naabu -iL new_subdomains.txt | notify $silent_mode

    # Run nuclei on the new subdomains if nuclei_mode is true
    if $nuclei_mode; then
        nuclei -l new_subdomains.txt -t "$template_path" -o nuclei_output.txt -as | notify $silent_mode
    fi

    # Clear the output file for the next iteration
    > "$output_file"

    # Wait for specified loop time before next iteration
    sleep "$loop_time" 
done

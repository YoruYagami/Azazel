#!/bin/bash

# Adding some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Install Katana
if ! command -v katana &> /dev/null; then
    echo -e "${RED}Installing Katana...${NC}"
    go install github.com/projectdiscovery/katana/cmd/katana@latest
    echo -e "${GREEN}Katana has been installed.${NC}"
else
    echo -e "${GREEN}Katana is already installed.${NC}"
fi

# Install assetfinder
if ! command -v assetfinder &> /dev/null; then
    echo -e "${RED}Installing assetfinder...${NC}"
    go install github.com/tomnomnom/assetfinder@latest
    echo -e "${GREEN}assetfinder has been installed.${NC}"
else
    echo -e "${GREEN}assetfinder is already installed.${NC}"
fi

# Install findomain
if ! command -v findomain &> /dev/null; then
    echo -e "${RED}Installing findomain...${NC}"
    go install github.com/Edu4rdSHL/findomain@latest
    echo -e "${GREEN}findomain has been installed.${NC}"
else
    echo -e "${GREEN}findomain is already installed.${NC}"
fi

# Install subfinder
if ! command -v subfinder &> /dev/null; then
    echo -e "${RED}Installing subfinder...${NC}"
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    echo -e "${GREEN}subfinder has been installed.${NC}"
else
    echo -e "${GREEN}subfinder is already installed.${NC}"
fi

# Install httpx
if ! command -v httpx &> /dev/null; then
    echo -e "${RED}Installing httpx...${NC}"
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
    echo -e "${GREEN}httpx has been installed.${NC}"
else
    echo -e "${GREEN}httpx is already installed.${NC}"
fi

# Install anew
if ! command -v anew &> /dev/null; then
    echo -e "${RED}Installing anew...${NC}"
    go install github.com/tomnomnom/anew@latest
    echo -e "${GREEN}anew has been installed.${NC}"
else
    echo -e "${GREEN}anew is already installed.${NC}"
fi

# Install nuclei
if ! command -v nuclei &> /dev/null; then
    echo -e "${RED}Installing nuclei...${NC}"
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 
    echo -e "${GREEN}nuclei has been installed.${NC}"
else
    echo -e "${GREEN}nuclei is already installed.${NC}"
fi


echo -e "${GREEN}All tasks have been completed successfully.${NC}"



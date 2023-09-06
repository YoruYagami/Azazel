#!/bin/bash

# Adding some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Install ParamSpider
if ! command -v paramspider &> /dev/null; then
    echo -e "${RED}Installing ParamSpider...${NC}"
    git clone https://github.com/devanshbatham/ParamSpider.git "$HOME/ParamSpider"
    cd $HOME/ParamSpider
    pip install .
    rm -rf "$HOME/ParamSpider"
    echo -e "${GREEN}ParamSpider has been installed.${NC}"
else
    echo -e "${GREEN}ParamSpider is already installed.${NC}"
fi

if ! command -v openredirex &> /dev/null; then
    echo -e "${RED}Installing openredirex...${NC}"
    git clone https://github.com/devanshbatham/openredirex "$HOME/openredirex"
    cd $HOME/openredirex
    sudo chmod +x setup.sh
    ./setup.sh
    rm -rf "$HOME/openredirex"
    echo -e "${GREEN}openredirex has been installed.${NC}"
else
    echo -e "${GREEN}openredirex is already installed.${NC}"
fi

# Install Katana
if ! command -v katana &> /dev/null; then
    echo -e "${RED}Installing Katana...${NC}"
    go install github.com/projectdiscovery/katana/cmd/katana@latest
    echo -e "${GREEN}Katana has been installed.${NC}"
else
    echo -e "${GREEN}Katana is already installed.${NC}"
fi

# Set the destination directory for gf-patterns
mkdir -p "$HOME/.gf"
TARGET_DIR="$HOME/.gf"

# Clone each repository and search for JSON patterns
for repo in \
    # Your list of repositories here
do
    echo -e "${YELLOW}Cloning $repo...${NC}"
    
    # Check if the repository is public
    if curl -s -I "$repo" | grep -q "HTTP/.* 200"; then
        # Clone the repository with the --depth 1 option to only download the latest commit
        git clone --depth 1 "$repo"

        # Search for JSON patterns recursively
        find . -name "*.json" -exec mv {} "$TARGET_DIR" \; 2>/dev/null
        find . -name "*.JSON" -exec mv {} "$TARGET_DIR" \; 2>/dev/null
        find . -name "*.geojson" -exec mv {} "$TARGET_DIR" \; 2>/dev/null
        find . -name "*.GeoJSON" -exec mv {} "$TARGET_DIR" \; 2>/dev/null

        # Remove the cloned repository
        echo -e "${RED}Removing $repo...${NC}"
        rm -rf $(basename "$repo")
    else
        echo -e "${RED}$repo is no longer public or has been deleted. Moving to the next...${NC}"
    fi
done

echo -e "${GREEN}All tasks have been completed successfully.${NC}"



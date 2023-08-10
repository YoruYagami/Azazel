#!/bin/bash

# Adding some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Install ParamSpider
if [[ ! -d "$HOME/ParamSpider" ]]; then
    echo -e "${RED}Installing ParamSpider...${NC}"
    git clone https://github.com/devanshbatham/ParamSpider.git "$HOME/ParamSpider"
    echo -e "${GREEN}ParamSpider has been installed.${NC}"
else
    echo -e "${GREEN}ParamSpider is already installed.${NC}"
fi

# Install nikto
if ! command -v nikto &> /dev/null; then
    echo -e "${RED}Installing nikto...${NC}"
    sudo apt install nikto
    echo -e "${GREEN}nitko has been installed.${NC}"
else
    echo -e "${GREEN}nikto is already installed.${NC}"
fi

# Install getJS
if ! command -v getJS &> /dev/null; then
    echo -e "${RED}Installing getJS...${NC}"
    go install github.com/003random/getJS@latest
    echo -e "${GREEN}getJS has been installed.${NC}"
else
    echo -e "${GREEN}getJS is already installed.${NC}"
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



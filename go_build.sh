#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Symbols
CHECKMARK='\xE2\x9C\x94'
ROCKET='\xF0\x9F\x9A\x80'
CROSSMARK='\xE2\x9C\x98'
HOURGLASS='\xE2\x8C\x9B'

# Check if Go module is enabled
if go env GOMOD &> /dev/null; then
    echo -e "${BLUE}${HOURGLASS} Go module is enabled. Now building your program...${NC}"
else
    echo -e "${RED}${CROSSMARK} Go module is not enabled. Please enable it before continuing.${NC}"
    exit 1
fi

# Clean up build folder if it exists
if [ -d "_production" ]; then
    rm -rf "_production"
fi
mkdir -p "_production"

# Build program to production folder
go build -o "_production"

# Get the executable file name
executable=$(basename "_production"/*)
echo ""
echo -e "${GREEN}Build success!${NC}"

# Copy dependencies
echo ""
if [ $# -gt 0 ]; then
    echo -e "${MAGENTA}Copying dependencies...${NC}"
    for arg in "$@"; do
        if [ -e "$arg" ]; then
            cp -r "$arg" "_production/"
            echo -e "  ${MAGENTA}${CHECKMARK} $arg${NC}"
        else
            echo -e "  ${RED}${CROSSMARK} File or directory not found: $arg${NC}"
        fi
    done
    echo ""
    echo -e "${GREEN}All operations completed successfully!${NC}"
else
    echo -e "${ORANGE}Warning: No dependencies provided.${NC}"
fi

echo ""
echo -e "${ROCKET} You can now use ${BLUE}./_production/$executable${NC} to execute your program."

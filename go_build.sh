#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Symbols
CHECKMARK='\xE2\x9C\x94'
ROCKET='\xF0\x9F\x9A\x80'
CROSSMARK='\xE2\x9C\x98'
HOURGLASS='\xE2\x8C\x9B'

# Define docker builder filename
docker_builder="docker_builder.sh"

# Check if Go module is enabled
if go env GOMOD &> /dev/null; then
    echo -e "${BLUE}${HOURGLASS} Go module is enabled. Now building your program...${NC}"
else
    echo -e "${RED}${CROSSMARK} Go module is not enabled. Please enable it before continuing.${NC}"
    exit 1
fi

# Clean up build folder if it exists
if [ -d "$PWD/_production" ]; then
    rm -rf "$PWD/_production"
fi
mkdir -p "$PWD/_production"

# Build program to production folder
go build -o "$PWD/_production"

# Get the executable file name
executable=$(basename "$PWD/_production"/*)
echo ""
echo -e "${GREEN}Build success!${NC}"

# Copy dependencies
echo ""
if [ $# -gt 0 ]; then
    echo -e "${MAGENTA}Copying dependencies...${NC}"
    for arg in "$@"; do
        if [ -e "$arg" ]; then
            cp -r "$arg" "$PWD/_production/"
            echo -e "  ${MAGENTA}${CHECKMARK} $arg${NC}"
        else
            echo -e "  ${RED}${CROSSMARK} File or directory not found: $arg${NC}"
        fi
    done
else
    echo -e "${YELLOW}Warning: No dependencies provided.${NC}"
fi

# Check and create necessary dependencies
echo ""
if [ ! -f "$PWD/_production/$docker_builder" ] || [ ! -d "$PWD/_production/Dockerfiles" ] || [ ! -d "$PWD/_production/logs" ]; then
    echo -e "${MAGENTA}Creating necessary dependencies...${NC}"
fi
if [ ! -f "$PWD/_production/$docker_builder" ]; then
    cp "$docker_builder" "$PWD/_production/"
    echo -e "  ${MAGENTA}${CHECKMARK} $docker_builder${NC}"
fi
if [ ! -d "$PWD/_production/Dockerfiles" ]; then
    mkdir -p "$PWD/_production/Dockerfiles"
    echo -e "  ${MAGENTA}${CHECKMARK} Dockerfiles${NC}"
fi
if [ ! -d "$PWD/_production/logs" ]; then
    mkdir -p "$PWD/_production/logs"
    echo -e "  ${MAGENTA}${CHECKMARK} logs${NC}"
fi

# Gain the execute permission
chmod +x $PWD/_production/$executable
chmod +x $PWD/_production/$docker_builder

# Create run file
cat << EOF > $PWD/_production/run_in_background.sh
#!/bin/bash
nohup $PWD/_production/SpiderTrigger > $PWD/_production/nohup.log 2>&1 &
echo \$! > $PWD/_production/nohup_pid
echo -e "${GREEN}${CHECKMARK} SpiderTrigger started up in background successfully!${NC}"
EOF
chmod +x $PWD/_production/run_in_background.sh

# Create kill file
cat << EOF > $PWD/_production/kill_run_in_background.sh
#!/bin/bash
if [ -f "$PWD/_production/nohup_pid" ]; then
    pid=\$(cat $PWD/_production/nohup_pid)
    if [ -n "\$pid" ]; then
        echo -e "${MAGENTA}Killing process \$pid ...${NC}"
        kill \$pid
        rm $PWD/_production/nohup_pid
        echo -e "${GREEN}${CHECKMARK} Process killed.${NC}"
    else
        echo -e "${RED}${CROSSMARK} No process ID found in nohup_pid file.${NC}"
    fi
else
    echo -e "${RED}${CROSSMARK} nohup_pid file not found.${NC}"
fi
EOF
chmod +x $PWD/_production/kill_run_in_background.sh

echo ""
echo -e "${GREEN}All operations completed successfully!${NC}"
echo ""
echo -e "${ROCKET} You can now use ${BLUE}./_production/$executable${NC} to execute your program."
echo -e "${ROCKET}${YELLOW} To run your program in the background, use ${BLUE}./_production/run_in_background.sh${YELLOW}.${NC}"
echo -e "${ROCKET}${YELLOW} To stop the program running in the background, use ${BLUE}./_production/kill_run_in_background.sh${YELLOW}.${NC}"
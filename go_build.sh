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
else
    echo -e "${YELLOW}Warning: No dependencies provided.${NC}"
fi

# Check and create necessary dependencies
echo ""
if [ ! -f "_production/$docker_builder" ] || [ ! -d "_production/Dockerfiles" ] || [ ! -d "_production/logs" ]; then
    echo -e "${MAGENTA}Creating necessary dependencies...${NC}"
fi
if [ ! -f "_production/$docker_builder" ]; then
    cp "$docker_builder" "_production/"
    echo -e "  ${MAGENTA}${CHECKMARK} $docker_builder${NC}"
fi
if [ ! -d "_production/Dockerfiles" ]; then
    mkdir -p "_production/Dockerfiles"
    echo -e "  ${MAGENTA}${CHECKMARK} Dockerfiles${NC}"
fi
if [ ! -d "_production/logs" ]; then
    mkdir -p "_production/logs"
    echo -e "  ${MAGENTA}${CHECKMARK} logs${NC}"
fi

# Gain the execute permission
chmod +x ./_production/$executable
chmod +x ./_production/$docker_builder

# Create run file
cat << EOF > _production/run_in_background.sh
#!/bin/bash
nohup ./SpiderTrigger &
echo \$! > nohup_pid
EOF
chmod +x ./_production/run_in_background.sh

# Create kill file
cat << EOF > _production/kill_run_in_background.sh
#!/bin/bash
if [ -f "nohup_pid" ]; then
    pid=\$(cat nohup_pid)
    if [ -n "\$pid" ]; then
        echo "Killing process \$pid..."
        kill \$pid
        rm nohup_pid
        echo "Process killed."
    else
        echo "No process ID found in nohup_pid file."
    fi
else
    echo "nohup_pid file not found."
fi
EOF
chmod +x ./_production/kill_run_in_background.sh

echo ""
echo -e "${GREEN}All operations completed successfully!${NC}"
echo ""
echo -e "${ROCKET} You can now use ${BLUE}./_production/$executable${NC} to execute your program."
echo -e "${ROCKET}${YELLOW} To run your program in the background, use ${BLUE}./_production/run_in_background.sh${YELLOW}.${NC}"
echo -e "${ROCKET}${YELLOW} To stop the program running in the background, use ${BLUE}./_production/kill_run_in_background.sh${YELLOW}.${NC}"
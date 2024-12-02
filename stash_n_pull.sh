#!/usr/bin/env bash

set -euo pipefail  # Improved error handling
# -e: exit on error
# -u: treat unset variables as an error
# -o pipefail: ensure pipeline errors are captured

# Color definitions
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[0;34m'
MAGENTA='\033[1;35m'
LIGHT_BLUE='\033[1;36m'
NC='\033[0m' # No color

# ASCII Art Header
ascii_art_header() {
    cat << 'EOF'
   _____  __                __            _   __        ____          __ __
  / ___/ / /_ ____ _ _____ / /_          / | / /       / __ \ __  __ / // /
  \__ \ / __// __ `// ___// __ \ ______ /  |/ /______ / /_/ // / / // // / 
 ___/ // /_ / /_/ /(__  )/ / / //_____// /|  //_____// ____// /_/ // // /  
/____/ \__/ \__,_//____//_/ /_/       /_/ |_/       /_/     \__,_//_//_/ 
EOF
}

# Function to show ascii art header
show_ascii_header() {
    echo -e "${BLUE}"
    ascii_art_header
    echo -e "${NC}"
    sleep 1
}

# Function to greet the user
greet_user() {
    local username=$(whoami)
    echo -e "${ORANGE}Hello, $username-sama!${NC}"
}

# Function to display help information
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Maintains GitHub's Repositories"
    echo
    echo "Options:"
    echo "  -h, --help     Display this help message and exit"
    echo
    echo "This script will:"
    echo "  1. Stash changes"
    echo "  2. Pull in new changes recursively with modules"
    echo
    echo "Note: This script come as is, with 0 warranty!"
    exit 0
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# Function to confirm user action
confirm_action() {
    printf "${LIGHT_BLUE}This script maintains git repos. Do You Want To Run It Now? (y/N): ${NC}" 
    read confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${RED}!! Operation cancelled.${NC} "
        exit 0
    fi
}

# Function to stash and pull in all directories under ~/src/
stash_and_pull() {
    for dir in $HOME/src/*/; do
        if [ -d "$dir" ]; then
            if [ -d "$dir/.git" ]; then  # Check if it's a Git repository
                echo -e "${GREEN}==>> Processing directory: $(basename "$dir")${NC}"
                cd "$dir" || continue
                #git stash
                git pull --autostash --recurse-submodules
                sleep 3
                cd - > /dev/null || continue
            else
                echo -e "${RED}==>> Skipping non-Git directory: $dir${NC}"
            fi
        fi
    done
}

# Alchemist Den
main() {
    parse_arguments "$@"
    show_ascii_header
    greet_user
    confirm_action
    stash_and_pull
}

# call it !
main "$@"

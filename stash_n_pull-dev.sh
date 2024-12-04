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

# Function to get deps
deps() {
    local required_deps=(bash git)
    local missing_deps=()

    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}==>> Missing dependencies: ${missing_deps[*]}${NC}"
        echo -e "${LIGHT_BLUE}Do you want to install them? (y/N): ${NC}"
        read -r confirm_install
        if [[ $confirm_install =~ ^[Yy]$ ]]; then
            echo -e "${ORANGE}==>> Installing dependencies...${NC}"
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y "${missing_deps[@]}"
            elif command -v pacman &> /dev/null; then
                sudo pacman -Syu --noconfirm "${missing_deps[@]}"
            else
                echo -e "${RED}==>> No suitable package manager found.${NC}"
                sleep 1
                echo -e "${ORANGE}==>> Please install dependencies manually.${NC}"
            fi
        else
            echo -e "${RED}==>> Installation cancelled.${NC}"
            exit 1
        fi
    fi
}

# Function to confirm user action
confirm_action() {
    printf "${LIGHT_BLUE}This script maintains git repos. Do You Want To Run It Now? (y/N): ${NC}"
    read confirm
    if [[ ! $confirm =~ ^[Yy]$ && ! -z $confirm ]]; then
        echo -e "${RED}!! Operation cancelled.${NC} "
        exit 0
    fi
}

# Function to stash and pull in all directories under ~/src/
stash_pull() {
    local git_count=0      # variable to hold git count
    local updated_dirs=()  # Array to hold updated directory names
    # Process each directory
    for dir in $HOME/src/*/; do
        if [ -d "$dir" ]; then
            if [ -d "$dir/.git" ]; then
                git_count=$((git_count + 1))
                echo -e "${GREEN}==>> Processing repository: $(basename "$dir")${NC}"
                cd "$dir" || continue
                # Capture the output of git pull
                local output=$(git pull --autostash --recurse-submodules)
                # Check if the output indicates an update
                if [[ $output == *"Updating"* || $output == *"Fast-forward"* ]]; then
                    updated_dirs+=("$(basename "$dir")")  # Add to updated directories
                fi
                sleep 2
                cd - > /dev/null || continue
            else
                echo -e "${RED}   ~> Skipping non-Git repositories: $(basename "$dir")${NC}"
            fi
        fi
    done
    # Display the total git directories found and total updated
    if [ -z "$(ls -A $HOME/src/)" ]; then
        echo -e "${RED}!!   ->> No directories found in $HOME/src/.${NC}"
        exit 1
    else
        echo -e "${MAGENTA} ->> Total Git repositories: $git_count ${NC}"
        if [ $git_count -eq 0 ]; then
            echo -e "${RED}!!   ->> No Git repositories found.${NC}"
        elif [ ${#updated_dirs[@]} -ne 0 ]; then
            echo -e "${MAGENTA} ->> Updated Git repositories: ${updated_dirs[*]} ${NC}"
        else
            echo -e "${MAGENTA} ->> No repositories were updated.${NC}"
        fi
    fi
}

# Alchemist Den
main() {
    parse_arguments "$@"
    show_ascii_header
    greet_user
    confirm_action
    deps
    stash_pull
}

# Shazaaamm!
main "$@"

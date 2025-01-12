#!/usr/bin/env bash

set -euo pipefail  # error handling
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

                                                   Qnk6IE1hZGUyRmxleA==
EOF
}

# Function to check if running in a terminal and offer to open one if not
get_script_path() {
    # Resolve the full path of the current script
    readlink -f "$0"
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
    echo -e "${ORANGE}Hello, $username ${NC}"
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
    printf "${LIGHT_BLUE}This script updates git repos. Do You Want To Run It Now? (y/N): ${NC}"
    read confirm
    if [[ ! $confirm =~ ^[Yy]$ && ! -z $confirm ]]; then
        echo -e "${RED}!! Operation cancelled.${NC} "
        exit 0
    fi
}

# Function to check if a repo is private and handle authentication
is_it_private() {
    local dir="$1"
    local remote_url
    
    # Get the remote URL
    remote_url=$(cd "$dir" && git remote get-url origin 2>/dev/null)
    
    # Check if remote URL contains 'https://' (more likely to need authentication), maybe?
    if [[ "$remote_url" == https://* ]]; then
        # Try a test fetch to check authentication
        if ! (cd "$dir" && GIT_TERMINAL_PROMPT=0 git fetch --dry-run &>/dev/null); then
            echo -e "${ORANGE} ->> Private repository detected: $(basename "$dir")${NC}"
            printf "${LIGHT_BLUE}Do you want to enter credentials for this repo? (y/N): ${NC}"
            read -r enter_creds
            
            if [[ $enter_creds =~ ^[Yy]$ ]]; then
                # Store credentials temporarily
                git config --global credential.helper 'cache --timeout=3600'
                return 0
            else
                echo -e "${ORANGE}==>> Skipping private repository: $(basename "$dir")${NC}"
                return 1
            fi
        fi
    fi
    
    return 0  # Repository is accessible
}

# Function to stash and pull in all directories under ~/src/
stash_pull() {
    local git_count=0      # Variable to hold git count
    local updated_dirs=()  # Array to hold updated directory names

    # Process each directory
    for dir in $HOME/src/*/; do
        if [ -d "$dir" ]; then
            if [ -d "$dir/.git" ]; then
                git_count=$((git_count + 1))
                echo -e "${GREEN}==>> Processing repository: $(basename "$dir")${NC}"
                cd "$dir" || continue

                # Check if repository is private and handle authentication
                if ! is_it_private "$dir"; then
                    cd - > /dev/null || continue
                    continue
                fi

                # Capture the output of git pull
                local output=$(git pull --autostash --recurse-submodules)

                # Check if the output indicates an update
                if [[ $output == *"Updating"* || $output == *"Fast-forward"* ]]; then
                    echo "$output"  # Display the full output only if there are updates
                    updated_dirs+=("$(basename "$dir")")  # Add to updated directories
                fi
                sleep 1
                cd - > /dev/null || continue
            else
                echo -e "${RED}   ~> Skipping non-Git repositories: $(basename "$dir")${NC}"
            fi
        fi
    done

    # Display the total Git directories found and total updated
    if [ -z "$(ls -A $HOME/src/)" ]; then
        echo -e "${RED}!!   ->> No directories found in $HOME/src/.${NC}"
        exit 1
    else
        echo -e "${MAGENTA} ->> Total Git repositories: $git_count ${NC}"
        if [ $git_count -eq 0 ]; then
            echo -e "${RED}!!   ->> No Git repositories found.${NC}"
        elif [ ${#updated_dirs[@]} -ne 0 ]; then
            echo -e "${MAGENTA} ->> Updated Git repositories: ${updated_dirs[*]} ${NC}"
            # Pass updated directories as arguments
            run_src_builder "${updated_dirs[@]}"
        else
            echo -e "${MAGENTA} ->> No repositories were updated.${NC}"
        fi
    fi
}

# Function to handle dependencies for src_builder
deps_build() {
    local required_deps=(make gcc cmake ninja)  # Core dependencies for building
    local missing_deps=()

    echo -e "${ORANGE}==>> Checking build dependencies...${NC}"
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}! Missing core build dependencies: ${missing_deps[*]}${NC}"
        echo -e "${BLUE} >> Each repo has its own build dependencies. Refer to their README.md file.${NC}"

        printf "${LIGHT_BLUE}Do you want to install them automatically? (y/N/pre-check only): ${NC}"
        read -r response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

        if [[ "$response" == "y" || "$response" == "yes" || -z "$answer" ]]; then
            echo -e "${ORANGE}  >> Installing missing dependencies...${NC}"
            if command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y "${missing_deps[@]}"
            elif command -v pacman &>/dev/null; then
                sudo pacman -Syu --noconfirm "${missing_deps[@]}"
            else
                echo -e "${RED}  >> No supported package manager found. Please install dependencies manually.${NC}"
                return 1
            fi
        elif [[ "$response" == "pre-check only" ]]; then
            echo -e "${LIGHT_BLUE}==>> Pre-check completed. Please install the following manually: ${missing_deps[*]}${NC}"
            return 1
        else
            echo -e "${RED}  >< Skipping dependency installation.${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}==>> All required dependencies are already ✓installed.${NC}"
    fi
    return 0
}


# Function to call src_builder.sh if there are updated repositories
run_src_builder() {
    local updated_dirs=("$@")  # Get the updated directories from arguments
    echo "Debug: Initial updated_dirs array contains: ${updated_dirs[@]}"

    while true; do
        printf "${MAGENTA}Do you want to build updated repos? (yes/no)${NC} "
        read -rp "" answer

        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')  # Normalize input

        if [[ "$answer" == "yes" || "$answer" == "y" || -z "$answer" ]]; then
            echo -e "${ORANGE}==>> Attempting to build updated repositories...${NC}"

             # Check for build dependencies
            if ! deps_build; then
                echo -e "${RED}!! Dependencies check failed. Skipping build process.${NC}"
                return 1
            fi

            local script_dir
            script_dir=$(dirname "$(get_script_path)")

            if [[ -f "$script_dir/src_builder" ]]; then
                # Serialize updated_dirs array into a string
                echo "Debug: Serializing updated_dirs array into a string: ${updated_dirs[@]}"
                local updated_dirs_string
                updated_dirs_string=$(printf '%s|' "${updated_dirs[@]}")
                updated_dirs_string=${updated_dirs_string%|}  # Remove trailing pipe
                echo "Debug: Serialized updated_dirs array string: $updated_dirs_string"


                # Pass serialized string as an environment variable
                UPDATED_DIRS="$updated_dirs_string" bash "$script_dir/src_builder"
            else
                echo -e "${RED}!! Build script not found! Please make sure it's in the same directory.${NC}"
                exit 2
            fi
            break
        elif [[ "$answer" == "no" || "$answer" == "n" ]]; then
            echo -e "${ORANGE}==>> Exiting...${NC}"
            exit 0
        else
            echo -e "${RED}Invalid input. Please respond with 'yes' or 'no'.${NC}"
        fi
    done
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

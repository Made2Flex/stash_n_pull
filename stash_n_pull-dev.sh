#!/usr/bin/env bash

set -euo pipefail  # error handling
# -e: exit on error
# -u: treat unset variables as an error
# -o: pipeline errors

# Color definitions
GREEN='\033[1;32m'
DARK_GREEN='\033[0;32m'
ORANGE='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[0;34m'
MAGENTA='\033[1;35m'
LIGHT_BLUE='\033[1;36m'
NC='\033[0m' # No color

author() {
    local message="$1"
    #local colors=("red" "orange" "cyan" "magenta" "dark green" "blue")
    local colors=("\033[1;31m" "\033[1;33m" "\033[1;36m" "\033[1;35m" "\033[0;32m" "\033[0;34m")
    local NC="\033[0m"
    local delay=0.1
    local iterations=${2:-5}  # customize as needed

    {
        for ((i=1; i<=iterations; i++)); do
            # Cycle through colors
            color=${colors[$((i % ${#colors[@]}))]}

            # Use \r to return to start of line, update with new color
            printf "\r${color}                                                   ${message}${NC}"

            sleep "$delay"
        done

        # Final clear line
        printf "\r\033[K"
        #printf "\n"
    } >&2
}

# Header
header() {
    cat << 'EOF'
   _____  __                __            _   __        ____          __ __
  / ___/ / /_ ____ _ _____ / /_          / | / /       / __ \ __  __ / // /
  \__ \ / __// __ `// ___// __ \ ______ /  |/ /______ / /_/ // / / // // /
 ___/ // /_ / /_/ /(__  )/ / / //_____// /|  //_____// ____// /_/ // // /
/____/ \__/ \__,_//____//_/ /_/       /_/ |_/       /_/     \__,_//_//_/
EOF
}

# Function to get the path of the script
get_script_path() {
    readlink -f "$0"
}

# Function to show header
show_header() {
    # Print the header in blue
    echo -e "${BLUE}"
    header
    author "Qnk6IE1hZGUyRmxleA=="
    echo -e "${NC}"
}

# Function to greet the user
greet_user() {
    local username=$(whoami)
    echo -e "${ORANGE}Hello, $username ${NC}"
}

# Function to display help information
show_help() {
    echo -e "${MAGENTA}Maintains GitHub's Repositories${NC}"
    echo
    echo -e "${LIGHT_BLUE}Usage:${NC} ${GREEN}$0${NC} ${BLUE}[OPTIONS]${NC}"
    echo
    echo -e "${LIGHT_BLUE}Options:${NC}"
    echo "  -h, --help     Display this help message and exit"
    echo
    echo -e "${LIGHT_BLUE}This script will:${NC}"
    echo -e "${GREEN}  1. Stash changes${NC}"
    echo -e "${GREEN}  2. Pull in new changes recursively with modules${NC}"
    echo -e "${GREEN}  3. Offer to build updated Repositories${NC}"
    echo
    echo -e "Note: This script comes as is, with ${ORANGE}NO GUARANTEE!${NC}"
    exit 0
}

# Function to parse help
parser() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                ;;
            *)
                echo -e "${RED}Error: This script does not accept arguments${NC}"
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
    printf "${LIGHT_BLUE}This script updates git repositories. Do You Want To Continue? (y/N): ${NC}"
    read confirm
    if [[ ! $confirm =~ ^[Yy]$ && ! -z $confirm ]]; then
        echo -e "${RED}!! Operation cancelled.${NC} "
        exit 0
    fi
}

# Function to check if a repository is private
# TODO: git doesn't accept passwords anymore. ask for keys
is_it_private() {
    local repo_dir="$1"
    local git_config="$repo_dir/.git/config"
    local remote_url

    # Check if .git/config exists
    if [[ ! -f "$git_config" ]]; then
        echo -e "${RED}   ~> Not a valid Git repository: $(basename "$repo_dir")${NC}"
        return 1
    fi

    # Get the remote URL
    remote_url=$(git -C "$repo_dir" config --get remote.origin.url 2>/dev/null)

    # Check if we got a valid URL
    if [[ -z "$remote_url" ]]; then
        echo -e "${ORANGE} ->> No remote URL found for: $(basename "$repo_dir")${NC}"
        return 1
    fi

    # attempt to access without credentials
    if git -C "$repo_dir" ls-remote --exit-code &>/dev/null; then
        return 0
    else
        echo -e "${ORANGE} ->> Repository appears to be private: $(basename "$repo_dir")${NC}"
        
        # Ask user if they want to enter credentials
        printf "${LIGHT_BLUE}Would you like to enter credentials for this repo? (y/N): ${NC}"
        read -r enter_creds
        if [[ "$enter_creds" =~ ^[Yy]$ ]]; then
            if [[ "$remote_url" =~ ^https:// ]]; then
                echo -e "${BLUE} ->> HTTPS repository detected${NC}"
                read -rp "Enter username: " git_username
                read -rsp "Enter password: " git_password
                echo
                git -C "$repo_dir" config --local credential.helper "store --file ~/.git-credentials-temp"
                echo "https://$git_username:$git_password@${remote_url#https://}" > ~/.git-credentials-temp
                
                # Test credentials
                if git -C "$repo_dir" ls-remote --exit-code &>/dev/null; then
                    return 0
                else
                    echo -e "${RED} ->> Authentication failed${NC}"
                fi
            else
                echo -e "${BLUE} ->> SSH repository detected - ensure your SSH key is properly configured${NC}"
            fi
        fi
        
        # Clean up temporary credentials
        if [[ -f ~/.git-credentials-temp ]]; then
            rm -f ~/.git-credentials-temp
            git -C "$repo_dir" config --local --unset credential.helper
        fi
        
        return 1
    fi
}

# Function to stash and pull in all directories under ~/src/
stash_pull() {
    local git_count=0
    local updated_dirs=()

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

                # Get current and remote HEAD hashes
                local current_hash=$(git rev-parse HEAD)
                git fetch --quiet
                local remote_hash=$(git rev-parse @{u})

                # Compare hashes
                if [ "$current_hash" != "$remote_hash" ]; then
                    # Perform the pull if updates are available
                    git pull --autostash --recurse-submodules
                    updated_dirs+=("$(basename "$dir")")
                    echo -e "${BLUE}==>> Repository updated successfully${NC}"
                else
                    echo -e "${ORANGE}  => Repository is up-to-date${NC}"
                fi

                cd - > /dev/null || continue
            else
                echo -e "${RED}   ~> Skipping non-Git repository: $(basename "$dir")${NC}"
            fi
        fi
    done

    # Display the total Git directories found and total updated
    if [ -z "$(ls -A $HOME/src/)" ]; then
        echo -e "${RED}!!   ->> No directories found in $HOME/src/.${NC}"
        exit 1
    else
        echo -e "${MAGENTA}==>> Total Git repositories:${NC} ${LIGHT_BLUE}$git_count ${NC}"
        if [ $git_count -eq 0 ]; then
            echo -e "${RED}!!   ->> No Git repositories found.${NC}"
        elif [ ${#updated_dirs[@]} -ne 0 ]; then
            echo -e "${MAGENTA}==>> Updated Git repositories:${NC} ${LIGHT_BLUE}${updated_dirs[*]} ${NC}"
            # Pass updated directories as arguments
            run_src_builder "${updated_dirs[@]}"
        else
            echo -e "${ORANGE}==>> No repositories were updated.${NC}"
        fi
    fi
}

# Function to handle dependencies for src_builder
# TODO: Proper Pre-check
build_deps() {
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
        echo -e "${BLUE} =>> Note, each repo has its own build dependencies. Refer to their README.md file.${NC}"

        printf "${LIGHT_BLUE}Do you want to install them automatically? (y/N/pre-check only): ${NC}"
        read -r response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

        if [[ "$response" == "y" || "$response" == "yes" || -z "$answer" ]]; then
            echo -e "${ORANGE} =>> Installing missing dependencies...${NC}"
            if command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y "${missing_deps[@]}"
            elif command -v pacman &>/dev/null; then
                sudo pacman -Syu --noconfirm "${missing_deps[@]}"
            else
                echo -e "${RED} =>> No supported package manager found. Please install dependencies manually.${NC}"
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
        echo -e "${GREEN}  => All required Core dependencies are ✓installed.${NC}"
    fi
    return 0
}


# Function to call src_builder.sh if there are updated repositories
run_src_builder() {
    local updated_dirs=("$@")  # Get the updated directories from arguments
    #echo "Debug: Initial updated_dirs array contains: ${updated_dirs[@]}"

    while true; do
        read -rp "$(echo -e "${LIGHT_BLUE}Do you want to build updated repos? (yes/no/select)${NC}")" answer

        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')  # Normalize input

        if [[ "$answer" == "yes" || "$answer" == "y" || -z "$answer" ]]; then
            echo -e "${ORANGE}==>> Attempting to build all updated repositories...${NC}"

            # Check for build dependencies
            if ! build_deps; then
                echo -e "${RED}!! Dependencies check failed. Skipping build process.${NC}"
                return 1
            fi

            local script_dir
            script_dir=$(dirname "$(get_script_path)")

            if [[ -f "$script_dir/src_builder" ]]; then
                # Serialize updated_dirs array into a string
                #echo "Debug: Serializing updated_dirs array into a string: ${updated_dirs[@]}"
                local updated_dirs_string
                updated_dirs_string=$(printf '%s|' "${updated_dirs[@]}")
                updated_dirs_string=${updated_dirs_string%|}  # Remove trailing pipe
                #echo "Debug: Serialized updated_dirs array string: $updated_dirs_string"


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
        elif [[ "$answer" == "select" || "$answer" == "s" ]]; then
            echo -e "${ORANGE}==>> Please select the repositories you want to build:${NC}"
            for i in "${!updated_dirs[@]}"; do
                echo "$((i+1)). ${updated_dirs[$i]}"
            done
            read -rp "$(echo -e "${LIGHT_BLUE}Enter the numbers of the repositories you want to build (${NC}${MAGENTA}comma-separated${NC}${LIGHT_BLUE}):${NC}")" selected_indices

            # Convert selected indices to array
            IFS=',' read -r -a selected_indices <<< "$selected_indices"

            # Filter updated_dirs based on selected indices
            local selected_dirs=()
            for index in "${selected_indices[@]}"; do
                if [[ $index -ge 1 && $index -le ${#updated_dirs[@]} ]]; then
                    selected_dirs+=("${updated_dirs[$((index-1))]}")
                else
                    echo -e "${RED}Invalid selection: $index${NC}"
                fi
            done

            if [ ${#selected_dirs[@]} -eq 0 ]; then
                echo -e "${RED}No valid repositories selected. Exiting...${NC}"
                exit 1
            fi

            echo -e "${ORANGE}==>> Attempting to build selected repositories:${NC} ${LIGHT_BLUE}${selected_dirs[*]}${NC}"

            # Check build dependencies
            if ! build_deps; then
                echo -e "${RED}!! Dependencies check failed. Aborting build process.${NC}"
                return 1
            fi

            local script_dir
            script_dir=$(dirname "$(get_script_path)")

            if [[ -f "$script_dir/src_builder" ]]; then
                # Serialize selected_dirs array into a string
                local selected_dirs_string
                selected_dirs_string=$(printf '%s|' "${selected_dirs[@]}")
                selected_dirs_string=${selected_dirs_string%|}  # Remove trailing pipe

                # Pass serialized string as an environment variable
                UPDATED_DIRS="$selected_dirs_string" bash "$script_dir/src_builder"
            else
                echo -e "${RED}!! Build script not found! Please make sure it's in the same directory.${NC}"
                exit 2
            fi
            break
        else
            echo -e "${RED}Invalid input. Please respond with 'yes', 'no', or 'select'.${NC}"
        fi
    done
}

# Alchemist Den
main() {
    parser "$@"
    show_header
    greet_user
    confirm_action
    deps
    stash_pull
}

# Shazaaamm!
main "$@"

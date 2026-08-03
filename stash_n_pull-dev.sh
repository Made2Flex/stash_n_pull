#!/usr/bin/env bash

VERSION="0.1.0"

set -euo pipefail
# -e: exit on error
# -u: treat unset variables as an error
# -o: pipeline errors

# Color definitions
GREEN='\033[1;32m'
DARK_GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[0;34m'
MAGENTA='\033[1;35m'
LIGHT_BLUE='\033[1;36m'
NC='\033[0m' # No color

author() {
    local message="$1"
    #local colors=("red" "yellow" "cyan" "magenta" "dark green" "blue")
    local colors=("\033[1;31m" "\033[1;33m" "\033[1;36m" "\033[1;35m" "\033[0;32m" "\033[0;34m")
    local NC="\033[0m"
    local delay=0.1
    local iterations=${2:-5}  # customizable

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

# get the path of the script
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
    echo -e "${YELLOW}Hello, $USER${NC}"
    exit 0
}

# Function to display help information
show_help() {
    echo -e "${GREEN}Maintains GitHub's Repositories${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0$ ${BLUE}[OPTIONS]${NC}"
    echo
    echo -e "${BLUE}Options:${NC}"
    echo "  -h, --help     Display this help message and exit"
    echo
    echo -e "$BLUE}This script will:${NC}"
    echo "  1. Stash changes"
    echo "  2. Pull in new changes recursively with modules"
    echo "  3. Offer to build updated Repositories"
    echo
    echo -e "${YELLOW}Note:${NC} This script comes as is, with ${RED}NO GUARANTEE!${NC}"
    exit 0
}

show_version() {
    echo -e "${GREEN}Version: $VERSION${NC}"
    exit 0
}

# Function to parse help
parser() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                ;;
            -v|--version)
                show_version
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

# Function to get dependencies
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
            echo -e "${YELLOW}==>> Installing dependencies...${NC}"
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y "${missing_deps[@]}"
            elif command -v pacman &> /dev/null; then
                sudo pacman -Syu --noconfirm "${missing_deps[@]}"
            else
                echo -e "${RED}==>> No suitable package manager found.${NC}"
                sleep 1
                echo -e "${YELLOW}==>> Please install dependencies manually.${NC}"
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

# Check if repository is accessible
is_repo_accessible() {
    local repo_dir="$1"
    local repo_name
    local remote_url

    repo_name=$(basename "$repo_dir")

    if [[ ! -d "$repo_dir/.git" ]]; then
        echo -e "${RED}   ~> Not a valid Git repository: ${repo_name}${NC}"
        return 1
    fi

    remote_url=$(git -C "$repo_dir" config --get remote.origin.url 2>/dev/null || true)

    if [[ -z "$remote_url" ]]; then
        echo -e "${YELLOW} ->> No remote URL found: ${repo_name}${NC}"
        return 1
    fi

    if ! GIT_TERMINAL_PROMPT=0 git -C "$repo_dir" fetch --dry-run &>/dev/null; then
        echo -e "${YELLOW}  ~>> Skipping inaccessible repository: ${RED}${repo_name}${NC}"
        return 1
    fi

    return 0
}

# Function to stash and pull in all directories under ~/src/
stash_pull() {
    local git_count=0
    local updated_dirs=()

    for dir in $HOME/src/*/; do
        if [ -d "$dir" ]; then
            if [ -d "$dir/.git" ]; then
                git_count=$((git_count + 1))
                echo -e "${YELLOW}==>> Processing repository: $(basename "$dir")${NC}"
                cd "$dir" || continue

                if ! is_repo_accessible "$dir"; then
                    cd - > /dev/null || continue
                    continue
                fi

                # Get current and remote HEAD hashes
                local current_hash=$(git rev-parse HEAD)
                GIT_TERMINAL_PROMPT=0 git fetch --quiet

                local remote_hash=$(git rev-parse @{u})

                # Compare hashes
                if [ "$current_hash" != "$remote_hash" ]; then
                    # pull if updates are available
                    git pull --autostash --recurse-submodules
                    updated_dirs+=("$(basename "$dir")")
                    echo -e "${BLUE}==>> Repository updated successfully${NC}"
                else
                    echo -e "${GREEN}  => Repository is up-to-date${NC}"
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
            echo -e "${YELLOW}==>> No repositories were updated.${NC}"
        fi
    fi
}

# Function to handle dependencies for src_builder
# TODO: Proper Pre-check
build_deps() {
    local required_deps=(make gcc cmake ninja)  # Core dependencies for building
    local missing_deps=()

    echo -e "${YELLOW}==>> Checking build dependencies...${NC}"
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}! Missing core build dependencies: ${missing_deps[*]}${NC}"
        echo -e "${BLUE} =>> Note, each repo has its own build dependencies. Refer to their README.md file.${NC}"

        printf "${LIGHT_BLUE}Do you want to install build dependencies automatically? (y/N/pre-check only): ${NC}"
        read -r response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

        if [[ "$response" == "y" || "$response" == "yes" || -z "$response" ]]; then
            echo -e "${YELLOW} =>> Installing missing dependencies...${NC}"
            if command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y "${missing_deps[@]}"
            elif command -v pacman &>/dev/null; then
                sudo pacman -Syu --noconfirm "${missing_deps[@]}"
            else
                echo -e "${RED} =>> No supported package manager found. Please install dependencies manually.${NC}"
                return 1
            fi
        elif [[ "$response" == "pre-check only" ]]; then
            # Helper: Report missing dependencies
            local actually_missing=()
            for dep in "${required_deps[@]}"; do
                if ! command -v "$dep" &>/dev/null; then
                    actually_missing+=("$dep")
                fi
            done

            if [ ${#actually_missing[@]} -eq 0 ]; then
                echo -e "${GREEN}==>> Pre-check: All required build dependencies are present!${NC}"
            else
                echo -e "${LIGHT_BLUE}==>> Pre-check results:${NC}"
                echo -e "${RED}   Missing the following core build dependencies:${NC} ${actually_missing[*]}"
                echo -e "${BLUE}==>> Please install them manually before proceeding.${NC}"
            fi
            return 1

        else
            echo -e "${RED}  >< Skipping dependency installation.${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}==>> All required Core dependencies are ✓installed.${NC}"
    fi
    return 0
}


# Function to call src_builder.sh if there are updated repositories
run_src_builder() {
    local updated_dirs=("$@")  # Get the updated directories from arguments
    #echo "Debug: Initial updated_dirs array contains: ${updated_dirs[@]}"

    while true; do
        read -rp "$(echo -e "${LIGHT_BLUE}Do you want to build updated repos? (yes/no/select)${NC}")" answer

        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

        if [[ "$answer" == "yes" || "$answer" == "y" || -z "$answer" ]]; then
            echo -e "${YELLOW}==>> Attempting to build all updated repositories...${NC}"

            # Check for build dependencies
            if ! build_deps; then
                echo -e "${RED}!! Dependencies check failed. Skipping build process.${NC}"
                return 1
            fi

            local script_dir
            script_dir=$(dirname "$(get_script_path)")

            if [[ -f "$script_dir/src_builder.sh" ]]; then
                # Serialize updated_dirs array into a string
                #echo "Debug: Serializing updated_dirs array into a string: ${updated_dirs[@]}"
                local updated_dirs_string
                updated_dirs_string=$(printf '%s|' "${updated_dirs[@]}")
                updated_dirs_string=${updated_dirs_string%|}  # Remove trailing pipe
                #echo "Debug: Serialized updated_dirs array string: $updated_dirs_string"


                # Pass serialized string as an environment variable
                UPDATED_DIRS="$updated_dirs_string" bash "$script_dir/src_builder.sh"
            else
                echo -e "${RED}!! Build script not found! Please make sure it's in the same directory with the name:${NC} ${MAGENTA}src_builder.sh.${NC}"
                exit 2
            fi
            break
        elif [[ "$answer" == "no" || "$answer" == "n" ]]; then
            echo -e "${YELLOW}==>> Exiting...${NC}"
            exit 0
        elif [[ "$answer" == "select" || "$answer" == "s" ]]; then
            echo -e "${YELLOW}==>> Please select the repositories you want to build:${NC}"
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

            echo -e "${YELLOW}==>> Attempting to build selected repositories:${NC} ${LIGHT_BLUE}${selected_dirs[*]}${NC}"

            # Check build dependencies
            if ! build_deps; then
                echo -e "${RED}!! Dependencies check failed. Aborting build process.${NC}"
                return 1
            fi

            local script_dir
            script_dir=$(dirname "$(get_script_path)")

            if [[ -f "$script_dir/src_builder.sh" ]]; then
                # Serialize selected_dirs array into a string
                local selected_dirs_string
                selected_dirs_string=$(printf '%s|' "${selected_dirs[@]}")
                selected_dirs_string=${selected_dirs_string%|}  # Remove trailing pipe

                # Pass serialized string as an environment variable
                UPDATED_DIRS="$selected_dirs_string" bash "$script_dir/src_builder.sh"
            else
                echo -e "${RED}!! Build script not found! Please make sure it's in the same directory with the name:${NC} ${MAGENTA}src_builder.sh.${NC}"
                exit 2
            fi
            break
        else
            echo -e "${RED}Invalid input. Please respond with 'yes', 'no', or 'select'.${NC}"
        fi
    done
}

# Alchemist's Den
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

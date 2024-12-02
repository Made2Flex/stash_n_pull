# Stash and Pull Script 🛠️

This Bash script is designed to help you maintain your GitHub repositories by stashing any local changes and pulling the latest updates from the remote repositories. It works recursively through all directories under `~/src/`.

## Features ✨

- **Stash Changes**: Automatically stashes any local changes before pulling updates.
- **Pull Updates**: Pulls the latest changes from the remote repository, including submodules.
- **User-Friendly**: Provides a colorful ASCII art header and greeting.
- **Help Information**: Displays usage instructions and options when requested.

## Usage 📖

To use the script, simply run it from the command line:

./stash_n_pull.sh [OPTIONS]

### Options:

- `-h`, `--help`: Display help information and exit.

## How It Works 🔧

1. **Stash Changes**: The script stashes any uncommitted changes in your Git repositories.
2. **Pull Updates**: It pulls the latest changes from the remote repository, including any submodules.
3. **Confirmation**: Before executing, the script asks for user confirmation to proceed.

## Requirements ⚙️

- Bash shell
- Git installed on your system

## Installation 📥

1. Clone this repository or download the script file.

git clone https://github.com/Made2Flex/stash_n_pull.git

3. Make the script executable:

   ```bash
   chmod +x stash_n_pull.sh
   ```
   
4. Place the script in a directory included in your `PATH` for easy access.

## Disclaimer ⚠️

This script comes as is, with no warranty. Use it at your own risk!

## Author 👤

Created by [Made2Flex](https://github.com/Made2Flex)

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


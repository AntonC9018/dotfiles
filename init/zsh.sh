set -euo pipefail

# Get the path to zsh
ZSH_PATH=$(which zsh)

# Ensure it's in /etc/shells (required on some Linux distros)
if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi

# Change the shell for the current user using sudo to skip the prompt
sudo chsh -s "$ZSH_PATH" "$USER"
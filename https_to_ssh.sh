#!/bin/bash

# Default to non-recursive
RECURSIVE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --recursive)
            RECURSIVE=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Function to convert HTTPS to SSH
convert_url() {
    echo "$1" | sed -E 's|https://github.com/([^/]+)/(.*)|git@github.com:\1/\2|'
}

# Define search parameters based on recursion flag
# If not recursive, we only check the current directory for .git
if [ "$RECURSIVE" = true ]; then
    FIND_CMD="find . -name .git"
else
    # -maxdepth 2 finds .git in the current dir (.) or immediate subdirs (./repo/.git)
    FIND_CMD="find . -maxdepth 2 -name .git"
fi

# Find git repositories
$FIND_CMD | while read -r gitpath; do
    repo_dir=$(dirname "$gitpath")
    echo "Processing Repo: $repo_dir"
    
    # Use a subshell ( ) instead of pushd/popd for cleaner scope management
    (
        cd "$repo_dir" || exit

        # 1. Update the main 'origin' remote
        current_url=$(git remote get-url origin 2>/dev/null)
        if [[ $current_url == https://github.com/* ]]; then
            new_url=$(convert_url "$current_url")
            echo "  Updating origin: $new_url"
            git remote set-url origin "$new_url"
        fi

        # 2. Update Submodules (if they exist)
        if [ -f ".gitmodules" ]; then
            echo "  Found .gitmodules, updating submodule URLs..."
            
            # Rewrite the .gitmodules file in-place
            sed -i -E 's|https://github.com/([^/ ]+)|git@github.com:\1|g' .gitmodules
            
            # Synchronize the git configuration with the new .gitmodules URLs
            git submodule sync --recursive > /dev/null
            echo "  Submodules synced."
        fi
    )
    echo "---"
done


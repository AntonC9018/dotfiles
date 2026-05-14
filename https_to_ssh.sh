#!/bin/bash

# Function to convert HTTPS to SSH
convert_url() {
    echo "$1" | sed -E 's|https://github.com/([^/]+)/(.*)|git@github.com:\1/\2|'
}

# Find all git repositories (including submodules which appear as .git files/dirs)
find . -name ".git" | while read -r gitpath; do
    repo_dir=$(dirname "$gitpath")
    echo "Processing Repo: $repo_dir"
    
    pushd "$repo_dir" > /dev/null || continue

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
        # This replaces https://github.com/ with git@github.com:
        # and adjusts the pathing (removing the slash after .com)
        sed -i -E 's|https://github.com/([^/ ]+)|git@github.com:\1|g' .gitmodules
        
        # Synchronize the git configuration with the new .gitmodules URLs
        git submodule sync --recursive > /dev/null
        echo "  Submodules synced."
    fi

    popd > /dev/null || return
    echo "---"
done

echo "Migration complete!"

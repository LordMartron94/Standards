#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="workspace.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: $CONFIG_FILE not found."
    exit 1
fi

echo "🔄 Synchronizing workspace modules..."

# Read line by line, ignoring comments and empty lines
while read -r dir name git_name github_name || [[ -n "$dir" ]]; do
    [[ -z "$dir" || "$dir" == \#* ]] && continue

    target_path="${dir}/${name}"
    self_hosted_url="ssh://git@localhost:22222/home/git/git-repos/${git_name}.git"

    # 1. Submodule Initialization / Addition
if ! git ls-files --error-unmatch "${target_path}" &>/dev/null; then
        echo "➜ Adding submodule: ${target_path}"
        git submodule add "${self_hosted_url}" "${target_path}"
    else
        echo "✔ Verified submodule index: ${target_path}"
        if [[ ! -e "${target_path}/.git" ]]; then
            echo "  ➜ Initializing missing payload..."
            git submodule update --init "${target_path}"
        fi
    fi
    # 2. Public Branch & Remote Wiring
    if [[ -n "${github_name}" && "${github_name}" != "-" ]]; then
        public_url="git@github.com:LordMartron94/${github_name}.git"
        
        (
            cd "${target_path}"
            
            # Check if the 'gh' remote exists
            if ! git remote get-url gh &>/dev/null; then
                echo "  🔗 Adding public remote 'gh' -> ${github_name}"
                git remote add gh "${public_url}"
            fi

            # Fetch the public remote safely
            git fetch gh 2>/dev/null || true

            # Handle the 'public' branch checkout
            if ! git show-ref --verify --quiet refs/heads/public; then
                echo "  🌿 Creating and checking out 'public' branch..."
                git checkout -B public
                # Attempt to link to the remote if it exists, otherwise it will link on first push
                git branch --set-upstream-to=gh/public public 2>/dev/null || true
            else
                echo "  ✔ 'public' branch exists. Checking it out..."
                git checkout public >/dev/null 2>&1
            fi
        )
    fi

done < "$CONFIG_FILE"

echo "✅ Workspace sync complete."
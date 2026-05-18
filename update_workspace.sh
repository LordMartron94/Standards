#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="workspace.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: $CONFIG_FILE not found."
    exit 1
fi

echo "⬇️ Updating workspace modules..."

while read -r dir name git_name github_name || [[ -n "$dir" ]]; do
    [[ -z "$dir" || "$dir" == \#* ]] && continue

    target_path="${dir}/${name}"

    # 1. Skip uninitialized modules
    if [[ ! -e "${target_path}/.git" ]]; then
        echo "⏭️  Skipping: ${target_path} (Not initialized)"
        continue
    fi

    echo "➜ Checking ${target_path}..."

    # 2. Skip if there are local, uncommitted changes
    if [[ -n "$(git -C "${target_path}" status --porcelain)" ]]; then
        echo "  ⚠️  Skipping: Local changes detected."
        continue
    fi

    # 3. Skip if in a detached HEAD state (not on a branch)
    current_branch=$(git -C "${target_path}" branch --show-current)
    if [[ -z "${current_branch}" ]]; then
        echo "  ⚠️  Skipping: Detached HEAD state."
        continue
    fi

    # 4. Pull safely
    echo "  ⬇️  Pulling latest changes for '${current_branch}'..."
    if git -C "${target_path}" pull --ff-only --quiet; then
         echo "  ✅ Up to date."
    else
         echo "  ❌ Failed to pull (Fast-forward impossible or network error)."
    fi

done < "$CONFIG_FILE"

echo "✅ Workspace update complete."
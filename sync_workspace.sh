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

    # 1. Submodule initialization / addition
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

    # 1b. Keep the shared Git hooks installed for this submodule.
    tools/scripts/install-git-hooks.sh "${target_path}"

    # 2. Public branch and GitHub remote wiring.
    if [[ -n "${github_name}" && "${github_name}" != "-" ]]; then
        public_url="git@github.com:LordMartron94/${github_name}.git"

        (
            cd "${target_path}"

            # This is a local configuration lookup: it does not contact GitHub.
            if ! git remote get-url gh &>/dev/null; then
                echo "  🔗 Adding public remote 'gh' -> ${github_name}"
                git remote add gh "${public_url}"
            fi

            # Do not fetch or contact GitHub here. The pre-push hook pushes
            # public to gh/public only when master is pushed to the private remote.
            if ! git show-ref --verify --quiet refs/heads/master; then
                echo "Error: ${target_path} has no local master branch." >&2
                exit 1
            fi

            if ! git show-ref --verify --quiet refs/heads/public; then
                echo "  🌿 Creating local public branch from master"
                git branch public master
            else
                echo "  ✔ Local public branch exists"
            fi
        )
    fi
done < "$CONFIG_FILE"

echo "✅ Workspace sync complete."
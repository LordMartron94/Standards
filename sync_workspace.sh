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
    indexed_entry="$(git ls-files --stage -- "${target_path}")"
    indexed_mode="${indexed_entry%% *}"

    # Tracked source directories, such as SQLite, have no submodule payload.
    if [[ -n "$indexed_entry" && "$indexed_mode" != "160000" ]]; then
        if [[ ! -d "$target_path" ]]; then
            echo "Error: tracked source directory is missing: $target_path" >&2
            exit 1
        fi
        echo "✔ Verified vendored source: ${target_path} (no submodule or hooks)"
        continue
    fi

    # 1. Submodule initialization / addition
    if [[ -z "$indexed_entry" ]]; then
        if [[ -z "$git_name" || "$git_name" == "-" ]]; then
            echo "Error: $target_path is not tracked and has no configured repository." >&2
            exit 1
        fi
        self_hosted_url="ssh://git@localhost:22222/home/git/git-repos/${git_name}.git"

        # Removed submodules can retain Git history here. Keep it intact and
        # clone the new repository under a distinct administrative name.
        submodule_name="$target_path"
        name_suffix=1
        while [[ -e "$(git rev-parse --git-path "modules/${submodule_name}")" ]] ||
              git config -f .gitmodules --get "submodule.${submodule_name}.path" >/dev/null 2>&1; do
            name_suffix=$((name_suffix + 1))
            submodule_name="${target_path}-${name_suffix}"
        done
        if [[ "$submodule_name" != "$target_path" ]]; then
            echo "  ➜ Preserving old submodule metadata; using name: $submodule_name"
        fi
        echo "➜ Adding submodule: ${target_path}"
        git submodule add --name "$submodule_name" "${self_hosted_url}" "${target_path}"
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

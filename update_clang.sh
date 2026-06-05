#!/usr/bin/env bash
set -euo pipefail

# Configuration
INSTALL_BASE="$HOME/.local/opt"
ACTIVE_SYMLINK="$INSTALL_BASE/llvm"
STAGING_DIR="$INSTALL_BASE/.staging"
API_URL="https://api.github.com/repos/llvm/llvm-project/releases/latest"
KEYS_URL="https://releases.llvm.org/release-keys.asc"
ASSET_PATTERN='LLVM-.*-Linux-X64\.tar\.xz$'
SIG_PATTERN='LLVM-.*-Linux-X64\.tar\.xz\.sig$'
KEEP_VERSIONS=2

# Unconditional Cleanup mechanism
cleanup() {
    if [ -d "$STAGING_DIR" ]; then
        echo "Purging volatile staging environment -> $STAGING_DIR"
        rm -rf "$STAGING_DIR"
    fi
}
# Register the cleanup function to trigger on ANY script exit (success, error, or interruption)
trap cleanup EXIT

fetch_release_data() {
    curl -sL "$API_URL"
}

extract_version() {
    local data="$1"
    echo "$data" | jq -r '.tag_name' | sed 's/llvmorg-//'
}

get_asset_url() {
    local data="$1"
    local pattern="$2"
    echo "$data" | jq -r --arg pat "$pattern" '.assets[] | select(.name | test($pat)) | .browser_download_url' | head -n 1
}

import_llvm_keys() {
    echo "Importing LLVM release keys..."
    curl -sL "$KEYS_URL" | gpg --import 2>/dev/null || true
}

verify_signature() {
    local archive="$1"
    local sig="$2"
    echo "Verifying cryptographic signature..."
    if ! gpg --verify "$sig" "$archive"; then
        echo "Fatal: Cryptographic verification failed. The archive may be compromised."
        exit 1
    fi
    echo "Signature verified successfully."
}

extract_archive() {
    local archive="$1"
    local target="$2"
    echo "Extracting archive to $target..."
    mkdir -p "$target"
    tar -xf "$archive" -C "$target" --strip-components=1
}

update_symlink() {
    local target="$1"
    local link="$2"
    echo "Updating active toolchain symlink..."
    ln -sfn "$target" "$link"
}

garbage_collect() {
    local base_dir="$1"
    echo "Running garbage collection..."
    
    local dirs
    mapfile -t dirs < <(find "$base_dir" -maxdepth 1 -mindepth 1 -type d -name "llvm-[0-9]*" | sort -V)
    
    local total=${#dirs[@]}
    if (( total <= KEEP_VERSIONS )); then
        echo "GC: $total version(s) found. No cleanup required."
        return 0
    fi
    
    local remove_count=$(( total - KEEP_VERSIONS ))
    for (( i=0; i<remove_count; i++ )); do
        echo "GC: Purging stale toolchain state -> ${dirs[$i]}"
        rm -rf "${dirs[$i]}"
    done
}

main() {
    echo "Querying LLVM GitHub API for the latest release..."
    local release_data
    release_data=$(fetch_release_data)
    
    local version
    version=$(extract_version "$release_data")
    local target_dir="$INSTALL_BASE/llvm-$version"

    echo "Latest stable version identified: $version"

    if [ -d "$target_dir" ]; then
        echo "Version $version is already active. Checking for stale states..."
        garbage_collect "$INSTALL_BASE"
        exit 0
    fi

    local archive_url
    archive_url=$(get_asset_url "$release_data" "$ASSET_PATTERN")
    
    local sig_url
    sig_url=$(get_asset_url "$release_data" "$SIG_PATTERN")

    if [[ -z "$archive_url" || -z "$sig_url" ]]; then
        echo "Fatal: Could not locate matching archive or signature URLs in the release payload."
        exit 1
    fi

    mkdir -p "$STAGING_DIR"
    local tmp_archive="$STAGING_DIR/llvm-$version.tar.xz"
    local tmp_sig="$STAGING_DIR/llvm-$version.tar.xz.sig"

    echo "Downloading archive to persistent staging..."
    curl -L "$archive_url" -o "$tmp_archive"
    
    echo "Downloading signature..."
    curl -L "$sig_url" -o "$tmp_sig"

    import_llvm_keys
    verify_signature "$tmp_archive" "$tmp_sig"
    
    extract_archive "$tmp_archive" "$target_dir"
    update_symlink "$target_dir" "$ACTIVE_SYMLINK"
    
    garbage_collect "$INSTALL_BASE"
    echo "Hermetic deployment of Clang/LLVM $version successful."
}

main
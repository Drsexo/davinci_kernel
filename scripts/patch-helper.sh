#!/bin/bash

# Patcher helper - 1.7
apply_patches() {
    for patch_url in "$@"; do
        echo "-- Applying patch: $(basename "$patch_url")"
        if [[ "$GITHUB_TOKEN" == "" ]]; then
            curl -sL --fail --retry 3 "$patch_url" -o /tmp/temp_patch.patch
        else
            curl -sL --fail --retry 3 -H "Authorization: Bearer $GITHUB_TOKEN" "$patch_url" -o /tmp/temp_patch.patch
        fi
        if [ -s /tmp/temp_patch.patch ]; then
            patch -s -p1 --fuzz=5 < /tmp/temp_patch.patch || { echo "Fatal: Failed to apply patch!"; exit 1; }
        else
            echo "Fatal: Failed to download patch from $patch_url"
            exit 1
        fi
    done
}

# Commit reverter - 1.7
revert_commit() {
    for patch_url in "$@"; do
        echo "-- Reverting commit: $(basename "$patch_url")"
        if [[ "$GITHUB_TOKEN" == "" ]]; then
            curl -sL --fail --retry 3 "$patch_url" -o /tmp/temp_revert.patch
        else
            curl -sL --fail --retry 3 -H "Authorization: Bearer $GITHUB_TOKEN" "$patch_url" -o /tmp/temp_revert.patch
        fi
        if [ -s /tmp/temp_revert.patch ]; then
            patch -R -s -p1 < /tmp/temp_revert.patch || { echo "Fatal: Failed to revert commit!"; exit 1; }
        else
            echo "Fatal: Failed to download revert patch from $patch_url"
            exit 1
        fi
    done
}
#!/usr/bin/env bash
#
# Preflight check for the Twyn iOS SDK.
#
# Verifies that git can reach the PRIVATE repos (twyn-ios-sdk + twyn-sdk-dist)
# BEFORE you run `pod install`, and prints an actionable message when it cannot
# (missing credentials, no org access, wrong tag, ...).
#
# Usage:
#   bash scripts/check-access.sh [sdk-tag] [cores-tag]

set -u

SDK_REPO="https://github.com/twyn-internal/twyn-ios-sdk.git"
DIST_REPO="https://github.com/twyn-internal/twyn-sdk-dist.git"
SDK_TAG="${1:-ios-0.2.0}"
DIST_TAG="${2:-ios-0.2.0}"

echo "Twyn iOS SDK - access check"
echo "  sdk:    $SDK_REPO @ $SDK_TAG"
echo "  cores:  $DIST_REPO @ $DIST_TAG"
echo

fail=0

check() {
    local repo="$1" tag="$2" label="$3" out rc
    out=$(git ls-remote "$repo" 2>&1); rc=$?

    if [ "$rc" -ne 0 ]; then
        echo "[error] Cannot access $label"
        echo "        $repo"
        echo "$out" | sed 's/^/        /'
        case "$out" in
            *"could not read Username"*|*"terminal prompts disabled"*)
                echo "  -> Git has no credentials for github.com. Configure a PAT or SSH:"
                echo "     git config --global url.\"https://<USER>:<TOKEN>@github.com/\".insteadOf \"https://github.com/\""
                echo "     # or"
                echo "     git config --global url.\"git@github.com:\".insteadOf \"https://github.com/\"" ;;
            *"Authentication failed"*|*"Invalid username or token"*)
                echo "  -> Your git credentials are invalid or expired (or lack access)." ;;
            *"Repository not found"*|*"not found"*)
                echo "  -> Your GitHub account has not been added to 'twyn-internal'. Ask Twyn." ;;
            *)
                echo "  -> Check your network connection and git configuration." ;;
        esac
        fail=1
        return
    fi

    if git ls-remote --tags "$repo" "refs/tags/$tag" | grep -q "refs/tags/$tag$"; then
        echo "[ok] $label - access granted, tag '$tag' found."
    else
        echo "[warn] $label - access granted, but tag '$tag' was not found. Available:"
        git ls-remote --tags "$repo" | sed -n 's#.*refs/tags/##p' | grep -v '\^{}' | sed 's/^/           /'
        fail=1
    fi
}

check "$SDK_REPO"  "$SDK_TAG"  "twyn-ios-sdk (TwynIOSSDK)"
check "$DIST_REPO" "$DIST_TAG" "twyn-sdk-dist (cores)"

echo
if [ "$fail" -eq 0 ]; then
    echo "All good. Next: add the pods to your Podfile and run 'pod install'."
    exit 0
fi
exit 1

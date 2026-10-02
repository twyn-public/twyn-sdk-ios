#!/usr/bin/env bash
#
# Preflight check for the Twyn iOS SDK.
#
# Verifies that git can reach the PRIVATE distribution repo
# (twyn-internal/twyn-sdk-dist) BEFORE you run `pod install`, and prints an
# actionable message when it cannot (missing credentials, no org access, ...).
#
# Usage:
#   bash scripts/check-access.sh [tag]
#
#   tag   distribution tag to check (default: ios-0.1.1)

set -u

REPO_URL="https://github.com/twyn-internal/twyn-sdk-dist.git"
TAG="${1:-ios-0.1.1}"

echo "Twyn iOS SDK - access check"
echo "  repo: $REPO_URL"
echo "  tag:  $TAG"
echo

# 1) Can git reach the repo at all? (may prompt once for credentials)
out=$(git ls-remote "$REPO_URL" 2>&1)
rc=$?

if [ "$rc" -ne 0 ]; then
    echo "[error] Cannot access the private repository."
    echo
    echo "$out" | sed 's/^/    /'
    echo
    case "$out" in
        *"could not read Username"*|*"terminal prompts disabled"*)
            echo "-> Git has no credentials for github.com."
            echo "   Configure a PAT or SSH (see README, 'Private repo credentials'):"
            echo "     git config --global url.\"https://<USER>:<TOKEN>@github.com/\".insteadOf \"https://github.com/\""
            echo "     # or"
            echo "     git config --global url.\"git@github.com:\".insteadOf \"https://github.com/\""
            ;;
        *"Authentication failed"*|*"Invalid username or token"*)
            echo "-> Your git credentials are invalid or expired (or lack access)."
            echo "   Regenerate your PAT (read access to the repo) or re-add your SSH key."
            ;;
        *"Repository not found"*|*"not found"*)
            echo "-> GitHub cannot see the repo for your account."
            echo "   This usually means your GitHub account has not been added to the"
            echo "   'twyn-internal' organization. Ask Twyn to grant you access."
            ;;
        *)
            echo "-> Check your network connection and git configuration."
            ;;
    esac
    exit 1
fi

# 2) Does the requested tag exist?
if git ls-remote --tags "$REPO_URL" "refs/tags/$TAG" | grep -q "refs/tags/$TAG$"; then
    echo "[ok] Access granted, tag '$TAG' found."
    echo
    echo "Next: add the pods to your Podfile and run 'pod install'."
else
    echo "[warn] Access granted, but tag '$TAG' was not found."
    echo "       Available tags:"
    git ls-remote --tags "$REPO_URL" | sed -n 's#.*refs/tags/##p' | grep -v '\^{}' | sed 's/^/         /'
    exit 2
fi

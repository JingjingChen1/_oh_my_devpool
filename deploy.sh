#!/usr/bin/env bash
set -euo pipefail
[ ! -t 0 ] && [ -r /dev/tty ] && exec </dev/tty
if [ -z "${GITHUB_TOKEN:-}" ]; then
    printf 'GitHub PAT: ' >&2; IFS= read -rs GITHUB_TOKEN; echo >&2
fi
[ -z "$GITHUB_TOKEN" ] && { echo "Token required" >&2; exit 1; }
curl -fsSL \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3.raw" \
    "https://api.github.com/repos/JingjingChen1/oh_my_devpool/contents/deploy.sh" \
    | GITHUB_TOKEN="$GITHUB_TOKEN" bash

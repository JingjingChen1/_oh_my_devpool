#!/usr/bin/env bash
# oh_my_devpool 公开入口: 校验 PAT → 拉取私有仓 deploy.sh → 执行
# 这份脚本应保持极简, 真正的部署逻辑在私有仓 deploy.sh, 此文件理论上无需再改动.
set -euo pipefail

# exec </dev/tty 必须在函数内执行. bash 从管道读脚本时按块读取, 若在顶层执行该 exec
# 会把 bash 后续读脚本的 stdin 切到 /dev/tty, 导致 `curl|bash` 卡死.
# 包进 main() 后函数体先完整载入, exec 只在调用时生效, 不再影响脚本读取.
main() {
    if [ ! -t 0 ]; then
        if [ -r /dev/tty ]; then
            exec </dev/tty
        else
            echo "stdin 不是 tty 且 /dev/tty 不可读, 请改为 'bash deploy.sh'" >&2
            exit 1
        fi
    fi
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        printf 'GitHub PAT: ' >&2; IFS= read -rs GITHUB_TOKEN; echo >&2
    fi
    [ -z "$GITHUB_TOKEN" ] && { echo "Token required" >&2; exit 1; }
    curl -fsSL \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3.raw" \
        "https://api.github.com/repos/JingjingChen1/oh_my_devpool/contents/deploy.sh" \
        | GITHUB_TOKEN="$GITHUB_TOKEN" bash
}

main "$@"

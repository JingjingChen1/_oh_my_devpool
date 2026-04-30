#!/usr/bin/env bash
# oh-my-devpool 公开入口: 校验 PAT → 拉取私有仓 deploy.sh → 执行
# 这份脚本应保持极简, 真正的部署逻辑在私有仓 deploy.sh, 此文件理论上无需再改动.
# 本文件是公开仓 _oh-my-devpool/deploy.sh 的源, 改动后需镜像到公开仓.
set -euo pipefail

# exec </dev/tty 必须在函数内执行. bash 从管道读脚本时按块读取, 若在顶层执行该 exec
# 会把 bash 后续读脚本的 stdin 切到 /dev/tty, 导致 `curl|bash` 卡死.
# 包进 main() 后函数体先完整载入, exec 只在调用时生效, 不再影响脚本读取.
main() {
    local __stdin_switched=0
    if [ ! -t 0 ]; then
        if [ -r /dev/tty ]; then
            exec 9<&0
            exec </dev/tty
            __stdin_switched=1
        else
            echo "stdin 不是 tty 且 /dev/tty 不可读, 请改为 'bash deploy.sh'" >&2
            exit 1
        fi
    fi
    # 允许通过环境变量覆盖私有部署入口，尽量避免未来改 wrapper 本身
    local DEPLOY_PRIVATE_REPO DEPLOY_REF DEPLOY_SCRIPT_PATH DEPLOY_API_URL
    DEPLOY_PRIVATE_REPO="${DEPLOY_PRIVATE_REPO:-JingjingChen1/oh-my-devpool}"
    DEPLOY_REF="${DEPLOY_REF:-main}"
    DEPLOY_SCRIPT_PATH="${DEPLOY_SCRIPT_PATH:-deploy.sh}"
    DEPLOY_API_URL="${DEPLOY_API_URL:-https://api.github.com/repos/${DEPLOY_PRIVATE_REPO}/contents/${DEPLOY_SCRIPT_PATH}?ref=${DEPLOY_REF}}"

    local DEPLOY_TOKEN_VAL
    if [ -n "${DEPLOY_TOKEN:-}" ]; then
        DEPLOY_TOKEN_VAL="$DEPLOY_TOKEN"
    else
        printf '部署凭据 (DEPLOY_TOKEN): ' >&2; IFS= read -rs DEPLOY_TOKEN_VAL; echo >&2
    fi
    [ -z "$DEPLOY_TOKEN_VAL" ] && { echo "DEPLOY_TOKEN required" >&2; exit 1; }
    curl -fsSL \
        -H "Authorization: token $DEPLOY_TOKEN_VAL" \
        -H "Accept: application/vnd.github.v3.raw" \
        "$DEPLOY_API_URL" \
        | DEPLOY_TOKEN="$DEPLOY_TOKEN_VAL" bash

    # 恢复原始 stdin（pipe），让 `curl | bash` 在脚本结束后正常退出。
    if [ "$__stdin_switched" = "1" ]; then
        exec 0<&9
        exec 9<&-
    fi
}

main "$@"

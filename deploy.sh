#!/usr/bin/env bash
# oh_my_devpool 公开部署入口
#
# 托管在公开仓库，无需鉴权即可 curl；内部交互式要求输入 GitHub PAT，
# 校验通过后从私有仓拉取并执行真正的 deploy.sh。
#
# 使用方式（把此文件放到任意公开仓库后）：
#   curl -fsSL https://raw.githubusercontent.com/<你的公开仓>/main/deploy.sh | bash

set -euo pipefail

PRIVATE_DEPLOY_URL="https://api.github.com/repos/JingjingChen1/oh_my_devpool/contents/deploy.sh"

# curl | bash 场景下把 stdin 接到终端以支持交互
if [ ! -t 0 ] && [ -r /dev/tty ]; then
    exec </dev/tty
fi

# 优先读环境变量，否则隐藏式交互输入
if [ -n "${GITHUB_TOKEN:-}" ]; then
    _tok="$GITHUB_TOKEN"
else
    printf 'GitHub PAT (至少 repo read 权限): ' >&2
    IFS= read -rs _tok; echo >&2
fi

[ -z "$_tok" ] && { echo "[ERR] Token 不能为空" >&2; exit 1; }

# 验证 token
_user=$(curl -fsSL \
    -H "Authorization: Bearer $_tok" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/user 2>/dev/null \
    | sed -n 's/.*"login":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || true)
[ -n "$_user" ] || { echo "[ERR] Token 无效（401 / 网络异常）" >&2; exit 1; }
echo "[INFO] Token 有效，GitHub 用户: $_user" >&2

# 拉取并执行私有仓 deploy.sh，把 token 传进去
exec curl -fsSL \
    -H "Authorization: token $_tok" \
    -H "Accept: application/vnd.github.v3.raw" \
    "$PRIVATE_DEPLOY_URL" | GITHUB_TOKEN="$_tok" bash

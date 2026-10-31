#!/bin/bash
# 把站点发布到 GitHub Pages: deploy_pages.sh <站点目录> <仓库名> [--private]
# 需要已登录的 gh。只推送 index.html / img / .gitignore / README，先做密钥扫描。
set -euo pipefail
SITE="$(cd "${1:?用法: deploy_pages.sh <站点目录> <仓库名>}" && pwd)"
REPO="${2:?缺少仓库名}"
VIS="--public"; [ "${3:-}" = "--private" ] && VIS="--private"
cd "$SITE"

# ---- secret scan: refuse to publish anything that looks like a key ----
if grep -rIlE '(sk-[A-Za-z0-9_-]{16,}|Bearer [A-Za-z0-9._-]{16,}|JELLY_API_KEY=.+|[0-9a-f]{40,})' \
     --exclude-dir=.git --exclude-dir=raw --exclude=.env --exclude=.env.example . ; then
  echo "❌ 上面这些文件里像是有密钥，已停止发布。删掉后再试。" >&2; exit 1
fi
[ -f img/faces.json ] || { echo "❌ 缺少 img/faces.json，先运行 prepare_faces.py 或 gen_faces.sh" >&2; exit 1; }

[ -d .git ] || git init -q -b main
[ -f .gitignore ] || printf '.env\nraw/\n.DS_Store\n' > .gitignore
git add index.html img .gitignore $( [ -f README.md ] && echo README.md )
git diff --cached --quiet || git commit -q -m "Publish jelly face site"

OWNER="$(gh api user -q .login)"
if ! gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  gh repo create "$REPO" $VIS --source . --push --description "Jelly face personal page"
else
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$OWNER/$REPO.git"
  git push -u origin main
fi
gh api "repos/$OWNER/$REPO/pages" >/dev/null 2>&1 \
  || gh api -X POST "repos/$OWNER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null
echo "✅ 已发布，1–2 分钟后可访问: https://$OWNER.github.io/$REPO/"

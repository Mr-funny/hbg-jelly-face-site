#!/bin/bash
# 复制模板到新目录: new_site.sh <站点目录> [--demo]
#   --demo  同时带上示例人物 Leo 的 9 张表情（虚构人物，AI 生成）
set -euo pipefail
DEST="${1:?用法: new_site.sh <站点目录> [--demo]}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
[ -e "$DEST/index.html" ] && { echo "$DEST 已经有 index.html，不覆盖" >&2; exit 1; }
mkdir -p "$DEST/img"
cp "$HERE/template/index.html" "$HERE/template/.gitignore" "$HERE/template/.env.example" "$DEST/"
if [ "${2:-}" = "--demo" ]; then cp "$HERE"/template/img/* "$DEST/img/"; fi
echo "已创建 $DEST"
echo "下一步：放表情图（prepare_faces.py）或生成（gen_faces.sh），然后本地预览："
echo "  python3 -m http.server 8801 --directory \"$DEST\""

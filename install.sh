#!/bin/sh
set -eu

repo="Mr-funny/hbg-jelly-face-site"
skill_name="hbg-jelly-face-site"
mode="claude"
explicit_target=""
temp_dir=""

usage() {
  cat <<'EOF'
Usage: install.sh [--codex] [--target DIR]

Installs hbg-jelly-face-site into Claude Code (~/.claude/skills) by default.
Use --codex for ~/.codex/skills or --target for an explicit directory.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --codex) mode="codex" ;;
    --claude) mode="claude" ;;
    --target)
      shift
      [ "$#" -gt 0 ] || { echo "--target requires a directory" >&2; exit 2; }
      explicit_target="$1"
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

cleanup() {
  if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
    rm -rf "$temp_dir"
  fi
}
trap cleanup EXIT INT TERM

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || true)
if [ -n "$script_dir" ] && [ -f "$script_dir/skill/$skill_name/SKILL.md" ]; then
  source_skill="$script_dir/skill/$skill_name"
else
  command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
  command -v tar >/dev/null 2>&1 || { echo "tar is required" >&2; exit 1; }
  temp_dir=$(mktemp -d)
  curl -fsSL "https://github.com/$repo/archive/refs/heads/main.tar.gz" \
    | tar -xz -C "$temp_dir"
  source_skill="$temp_dir/hbg-jelly-face-site-main/skill/$skill_name"
fi

if [ -n "$explicit_target" ]; then
  target="$explicit_target"
elif [ "$mode" = "codex" ]; then
  target="${CODEX_HOME:-$HOME/.codex}/skills/$skill_name"
else
  target="${CLAUDE_HOME:-$HOME/.claude}/skills/$skill_name"
fi

if [ -e "$target" ]; then
  backup="${target}.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$target" "$backup"
  echo "Backed up existing skill: $backup"
fi

mkdir -p "$target"
cp -R "$source_skill"/. "$target"/
chmod +x "$target"/scripts/*.sh "$target"/scripts/*.py

test -f "$target/SKILL.md"
test -f "$target/agents/openai.yaml"
test -f "$target/template/index.html"
test -f "$target/template/img/faces.json"

for script in "$target"/scripts/*.sh; do
  bash -n "$script"
done
python3 -m py_compile "$target"/scripts/*.py
rm -rf "$target"/scripts/__pycache__

echo "Installed $skill_name to $target"
echo "Use: 使用 \$$skill_name 用我的照片做一个果冻拳王小游戏，并发布到 GitHub Pages。"

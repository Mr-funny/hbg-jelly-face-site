#!/usr/bin/env python3
"""Fail if anything that looks like a credential or a private local path is about to be published."""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PATTERNS = {
    "OpenAI-style key": re.compile(r"sk-[A-Za-z0-9_-]{20,}"),
    "bearer token": re.compile(r"Bearer\s+[A-Za-z0-9._-]{20,}"),
    "filled-in JELLY_API_KEY": re.compile(r"JELLY_API_KEY=[A-Za-z0-9._-]{8,}"),
    "long hex secret": re.compile(r"\b[0-9a-f]{40,}\b"),
    "GitHub token": re.compile(r"gh[pousr]_[A-Za-z0-9]{30,}"),
    "macOS home path": re.compile(r"/Users/[A-Za-z0-9._-]+/"),
    "Linux home path": re.compile(r"/home/[A-Za-z0-9._-]+/"),
}
BLOCKED_FILES = {".env"}
TEXT_EXT = {".md", ".sh", ".py", ".html", ".json", ".yaml", ".yml", ".txt", ".example", ".gitignore", ".svg", ""}

try:
    files = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard"],
                           cwd=ROOT, capture_output=True, text=True, check=True).stdout.split()
except Exception:
    files = [str(p.relative_to(ROOT)) for p in ROOT.rglob("*") if p.is_file() and ".git" not in p.parts]

problems = []
for rel in files:
    p = ROOT / rel
    if p.name in BLOCKED_FILES:
        problems.append(f"{rel}: .env files must never be committed")
        continue
    if p.suffix not in TEXT_EXT or not p.is_file():
        continue
    text = p.read_text(encoding="utf-8", errors="ignore")
    for label, rx in PATTERNS.items():
        for m in rx.finditer(text):
            line = text.count("\n", 0, m.start()) + 1
            problems.append(f"{rel}:{line}: looks like a {label}")

if problems:
    print("\n".join(f"✗ {p}" for p in problems))
    sys.exit(1)
print(f"✓ no secrets or private paths in {len(files)} files")

#!/usr/bin/env python3
"""Check that the skill folder has everything an agent needs, and that the demo set is self-consistent."""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILL = ROOT / "skill" / "hbg-jelly-face-site"
REQUIRED = [
    "SKILL.md", "LICENSE", "agents/openai.yaml",
    "references/api-config.md", "references/tuning.md", "references/quality-gate.md",
    "scripts/new_site.sh", "scripts/gen_faces.sh", "scripts/prepare_faces.py", "scripts/deploy_pages.sh",
    "template/index.html", "template/.gitignore", "template/.env.example", "template/img/faces.json",
]
FRONTMATTER = ["name", "version", "display_name", "display_name_en", "description_zh", "description_en", "description"]

errors = []
for rel in REQUIRED:
    if not (SKILL / rel).is_file():
        errors.append(f"missing {rel}")

text = (SKILL / "SKILL.md").read_text(encoding="utf-8")
m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
if not m:
    errors.append("SKILL.md has no frontmatter")
else:
    keys = {line.split(":", 1)[0].strip() for line in m.group(1).splitlines() if ":" in line}
    errors += [f"frontmatter missing {k}" for k in FRONTMATTER if k not in keys]
    if f"name: {SKILL.name}" not in m.group(1):
        errors.append("frontmatter name must match the folder name")

# every image referenced by the demo faces.json must exist
img = SKILL / "template" / "img"
faces = json.loads((img / "faces.json").read_text(encoding="utf-8"))
refs = [faces["base"], *faces.get("pain", []), *faces.get("fun", [])]
for k, v in faces.get("boxing", {}).items():
    if k == "stages":
        refs += [f for st in v for f in st.values()]
    else:
        refs.append(v)
errors += [f"faces.json points at missing img/{r}" for r in refs if not (img / r).is_file()]

# links between docs
for md in SKILL.rglob("*.md"):
    for link in re.findall(r"\]\(([^)#]+\.md)\)", md.read_text(encoding="utf-8")):
        if not (md.parent / link).is_file():
            errors.append(f"{md.relative_to(ROOT)} links to missing {link}")

if errors:
    print("\n".join(f"✗ {e}" for e in errors))
    sys.exit(1)
print(f"✓ skill structure ok ({len(refs)} demo images referenced)")

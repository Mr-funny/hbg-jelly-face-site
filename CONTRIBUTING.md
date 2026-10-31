# Contributing

Issues and PRs are welcome, especially:

- new expression or injury prompts that stay consistent across a set
- better hit-zone detection for different face framings
- additional game modes (the template keeps every mode in one static `index.html`)
- support for more OpenAI-compatible image backends

Before opening a PR:

```bash
python3 tools/validate_skill.py
python3 tools/check_secrets.py
for f in skill/hbg-jelly-face-site/scripts/*.sh; do bash -n "$f"; done
python3 -m py_compile skill/hbg-jelly-face-site/scripts/*.py
```

Also follow these rules:

- If you change the template, open it through a local server and play both modes.
- Keep the demo character fictional and AI-generated.
- Never commit photos of real people, API keys or `.env` files.

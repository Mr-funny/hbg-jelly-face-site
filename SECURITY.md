# Security policy

## Never include credentials in issues or pull requests

Do not upload any of the following:

- image API keys, `.env` files, or `~/.config/hbg-jelly-face/.env`
- GitHub tokens
- private photos of people who did not consent
- your `raw/` generation folders

The skill reads the image API key only from these places, and never writes it anywhere:

- the `JELLY_API_KEY` environment variable
- `<site>/.env`
- `~/.config/hbg-jelly-face/.env`

The key is passed to `curl` through stdin (`curl -K -`), so it never appears in process lists or shell history.

Published pages never call an image API at runtime: they ship static images only.

`deploy_pages.sh` and `tools/check_secrets.py` refuse to publish anything that looks like a key.

## People's faces

Only use photos of yourself, or of people who explicitly agreed. The boxing mode turns the face black and blue. Using someone else's face without consent is harassment, not a game.

## Reporting a vulnerability

Open a GitHub security advisory for:

- credential exposure
- unsafe path handling
- command injection
- installer problems

For ordinary bugs without sensitive data, use a normal Issue with a minimal redacted reproduction.

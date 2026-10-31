#!/bin/bash
# 用 OpenAI 兼容的图像接口生成一套表情图，然后交给 prepare_faces.py 写进 <site>/img/
#
# 用法:
#   gen_faces.sh <站点目录> [--prompt "人物描述"] [--photo 自己的照片.jpg] [--expressions grin,squint,...] [--skip-base]
#
# 密钥读取顺序（任何一处都不会被打印或写进站点）:
#   1. 环境变量 JELLY_API_KEY / JELLY_API_BASE / JELLY_IMAGE_MODEL
#   2. <站点目录>/.env            （已在 .gitignore 里）
#   3. ~/.config/hbg-jelly-face/.env
set -euo pipefail

SITE="${1:?用法: gen_faces.sh <站点目录> [--prompt ...] [--photo ...]}"; shift
HERE="$(cd "$(dirname "$0")" && pwd)"
PROMPT=""; PHOTO=""; SKIP_BASE=0; DAMAGE=0
EXPRS="grin,wink_tongue,crosseyed,surprised,squint,laugh,smirk,puff"
while [ $# -gt 0 ]; do
  case "$1" in
    --prompt) PROMPT="$2"; shift 2 ;;
    --photo) PHOTO="$2"; shift 2 ;;
    --expressions) EXPRS="$2"; shift 2 ;;
    --set)
      case "$2" in
        pinch) EXPRS="grin,wink_tongue,crosseyed,surprised,squint,laugh,smirk,puff" ;;
        boxing) EXPRS="hit_left,hit_right,uppercut,nose,wince,dizzy,ko,taunt" ;;
        all) EXPRS="grin,wink_tongue,crosseyed,surprised,squint,laugh,smirk,puff,hit_left,hit_right,uppercut,nose,wince,dizzy,ko,taunt"; DAMAGE=1 ;;
        damage) EXPRS=""; DAMAGE=1 ;;
        *) echo "--set 只能是 pinch / boxing / damage / all" >&2; exit 2 ;;
      esac; shift 2 ;;
    --skip-base) SKIP_BASE=1; shift ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

# ---- load config without echoing it ----
load_env() { [ -f "$1" ] || return 0; set -a; . "$1"; set +a; }
ENV_KEY="${JELLY_API_KEY:-}"; ENV_BASE="${JELLY_API_BASE:-}"; ENV_MODEL="${JELLY_IMAGE_MODEL:-}"
load_env "$HOME/.config/hbg-jelly-face/.env"
load_env "$SITE/.env"
KEY="${ENV_KEY:-${JELLY_API_KEY:-}}"
API="${ENV_BASE:-${JELLY_API_BASE:-https://api.openai.com/v1}}"; API="${API%/}"
MODEL="${ENV_MODEL:-${JELLY_IMAGE_MODEL:-gpt-image-1}}"
if [ -z "$KEY" ]; then
  cat >&2 <<'EOF'
没有找到图像接口密钥。任选一种方式配置（都不会进 git）：
  export JELLY_API_KEY=sk-...                     # 当前终端临时用
  或在 ~/.config/hbg-jelly-face/.env 写入：
    JELLY_API_KEY=sk-...
    JELLY_API_BASE=https://api.openai.com/v1      # 任意 OpenAI 兼容地址
    JELLY_IMAGE_MODEL=gpt-image-1
没有密钥也可以：直接用 prepare_faces.py 导入你自己的表情图。
EOF
  exit 3
fi
echo "接口: $API   模型: $MODEL   密钥: 已配置（不显示）"

RAW="$SITE/raw"; mkdir -p "$RAW"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# auth header goes through curl's stdin config so the key never shows up in `ps` or logs
auth() { printf 'header = "Authorization: Bearer %s"\n' "$KEY"; }

save_image() { # <response.json> <out.png>
  python3 -I - "$1" "$2" <<'PY'
import json, sys, base64, subprocess
src, out = sys.argv[1], sys.argv[2]
raw = open(src).read()
try:
    d = json.loads(raw)["data"][0]
except Exception:
    print("FAIL", out, raw[:400].replace("\n", " ")); sys.exit(1)
if d.get("b64_json"):
    open(out, "wb").write(base64.b64decode(d["b64_json"]))
else:
    subprocess.run(["curl", "-s", "-o", out, d["url"]], check=True)
print("ok", out)
PY
}

generate() { # <prompt> <out.png>
  python3 -I -c 'import json,sys;print(json.dumps({"model":sys.argv[1],"prompt":sys.argv[2],"size":"1024x1024","n":1,"background":"transparent","output_format":"png"}))' "$MODEL" "$1" > "$TMP/body.json"
  auth | curl -s -m 400 -K - "$API/images/generations" -H "Content-Type: application/json" -d @"$TMP/body.json" > "$TMP/$(basename "$2").json"
  save_image "$TMP/$(basename "$2").json" "$2"
}

edit() { # <prompt> <out.png> <input image>
  auth | curl -s -m 400 -K - "$API/images/edits" \
    -F "model=$MODEL" -F "prompt=$1" -F "image=@$3" -F size=1024x1024 -F background=transparent -F output_format=png \
    > "$TMP/$(basename "$2").json"
  save_image "$TMP/$(basename "$2").json" "$2"
}

FRAME="head and shoulders, facing the camera straight on, centered, head in the upper-middle of the frame, shoulders cut off at the bottom edge, soft even studio lighting, photorealistic, sharp detail. Fully transparent background, isolated cutout, no shadow."

# ---- 1. neutral base ----
if [ "$SKIP_BASE" = 0 ]; then
  if [ -n "$PHOTO" ]; then
    edit "Turn this photo into a clean portrait cutout of the same person: keep their identity, hair and clothing; $FRAME Neutral relaxed expression, mouth closed, eyes open looking at camera. ${PROMPT}" "$RAW/base.png" "$PHOTO"
  else
    : "${PROMPT:=a fictional friendly young adult with a distinctive hairstyle, wearing a plain dark crew-neck t-shirt}"
    generate "Studio portrait photo of ${PROMPT}. $FRAME Neutral relaxed expression with closed mouth, eyes open looking at camera." "$RAW/base.png"
  fi
fi
[ -f "$RAW/base.png" ] || { echo "没有 base.png，停止" >&2; exit 1; }

# ---- 2. expressions, edited from the base so identity and framing stay put ----
desc() {
  case "$1" in
    grin) echo "a huge toothy happy grin, eyes bright and open" ;;
    wink_tongue) echo "a playful wink with the left eye closed and the tongue sticking out to the side" ;;
    crosseyed) echo "silly goofy face: eyes crossed toward the nose, tongue sticking out" ;;
    surprised) echo "shocked surprised face: eyebrows raised high, eyes wide open, mouth open in a big O" ;;
    squint) echo "eyes squeezed tightly shut, nose scrunched, teeth clenched in an awkward cringe grin" ;;
    laugh) echo "laughing hard with eyes closed and mouth wide open" ;;
    smirk) echo "skeptical side-eye glance to the right with one eyebrow raised and a smug half smirk" ;;
    puff) echo "cheeks puffed full of air, lips pressed together, eyes wide" ;;
    # boxing set — comedic cartoon-style reactions, no blood or injuries
    hit_left) echo "comedic reaction to being punched on the cheek that is on the LEFT side of the image: that cheek squashed inward, face skewed and recoiling toward the right side of the image, eyes squeezed shut, mouth twisted sideways, lips pushed out, no blood, no injuries" ;;
    hit_right) echo "comedic reaction to being punched on the cheek that is on the RIGHT side of the image: that cheek squashed inward, face skewed and recoiling toward the left side of the image, eyes squeezed shut, mouth twisted sideways, lips pushed out, no blood, no injuries" ;;
    uppercut) echo "comedic reaction to an uppercut to the chin: chin jolted upward, eyes rolled up, mouth open with teeth clenched, cheeks wobbling, no blood, no injuries" ;;
    nose) echo "comedic reaction to being bonked on the nose: eyes crossed and watery, nose scrunched, mouth in a wavy grimace, no blood, no injuries" ;;
    wince) echo "wincing in pain after a hit: one eye shut, the other half open, teeth gritted, eyebrows knitted, no blood, no injuries" ;;
    dizzy) echo "dazed and dizzy like a cartoon after being punched: eyes unfocused and looking in different directions, goofy wobbly half smile, tongue slightly out, no injuries" ;;
    ko) echo "comically knocked out: eyes closed, eyebrows raised, mouth hanging wide open, totally limp face, no blood, no injuries" ;;
    taunt) echo "cocky taunting expression: chin up, one eyebrow raised, smug confident grin as if saying 'is that all you got?'" ;;
    *) echo "$1" | tr '_' ' ' ;;
  esac
}
KEEP="Keep exactly the same person, same identity, same hair, same clothing, same head position, size, framing and camera angle, same lighting, photorealistic. Transparent background, isolated cutout. Only change the facial expression to:"
LIST=(); [ -n "$EXPRS" ] && IFS=',' read -r -a LIST <<< "$EXPRS"
for e in ${LIST[@]+"${LIST[@]}"}; do edit "$KEEP $(desc "$e")." "$RAW/$e.png" "$RAW/base.png" & done
wait

# ---- 2b. boxing damage stages: each stage edits the previous one so injuries pile up ----
if [ "$DAMAGE" = 1 ]; then
  STAGE=(
    "light comedic boxing damage: a reddish bruise on the cheek on the left side of the image, a slightly red nose, a little sweat; same neutral expression"
    "more boxing damage on top of the existing bruises: a dark purple black eye on the left side of the image, a puffy swollen cheek on the right side of the image, a red swollen nose, a small band-aid on the forehead, slightly swollen lips; tired grumpy expression"
    "heavy cartoon boxing damage on top of the existing injuries: both eyes black, puffy and half shut, a big round lump bulging on the forehead, lumpy swollen cheeks, a band-aid across the nose, fat swollen lips; dazed expression"
    "maximum cartoon 'beaten to a pulp' look on top of the existing injuries: the whole face puffy and swollen like a balloon, both eyes swollen almost shut with dark purple bruises, several lumps on the head, crossed band-aids, swollen lips; comedic and goofy"
  )
  DKEEP="Keep exactly the same person, same hair, same clothing, same head position, size, framing and camera angle, photorealistic, comedic style, no blood, no open wounds. Transparent background, isolated cutout. Change:"
  prev="$RAW/base.png"
  for i in 1 2 3 4; do
    edit "$DKEEP ${STAGE[$((i-1))]}." "$RAW/dmg$i.png" "$prev"
    prev="$RAW/dmg$i.png"
  done
  HKEEP="Keep exactly the same person with exactly the same bruises, black eyes, swelling, lumps and band-aids, same hair, same clothing, same head position, size, framing and camera angle, photorealistic. Transparent background, isolated cutout. Only change the facial expression to:"
  for i in 1 2 3 4; do
    edit "$HKEEP $(desc hit_left)." "$RAW/dmg${i}_hit_left.png" "$RAW/dmg$i.png" &
    edit "$HKEEP $(desc hit_right)." "$RAW/dmg${i}_hit_right.png" "$RAW/dmg$i.png" &
  done
  edit "$HKEEP $(desc ko)." "$RAW/dmg4_ko.png" "$RAW/dmg4.png" &
  wait
fi

# ---- 3. hand off to prepare_faces (everything in raw/, so earlier sets are kept) ----
ARGS=("base=$RAW/base.png")
for f in "$RAW"/*.png; do n="$(basename "$f" .png)"; [ "$n" = base ] || ARGS+=("$n=$f"); done
python3 -I "$HERE/prepare_faces.py" "$SITE" "${ARGS[@]}"

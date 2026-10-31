#!/usr/bin/env python3
"""把一组表情图整理进站点：缩放成 900px 宽的 WebP（保留透明），写 img/faces.json。

用法:
  python3 prepare_faces.py <站点目录> base=中性.png grin=笑.png squint=挤眼.png ...
  python3 prepare_faces.py <站点目录> 中性.png 表情1.png 表情2.png        # 第一张当 base，其余按文件名命名
  python3 prepare_faces.py <站点目录> ... --pain squint,surprised          # 指定"被拽时"用哪些

分组规则：被拽时(pain)显示痛苦/惊讶类，松手后(fun)显示调皮类。
名字含 squint/surprised/crosseyed/puff/cringe/scared/angry/pain 的默认进 pain，其余进 fun。
需要 ffmpeg。
"""
import json, os, re, subprocess, sys

PAIN_HINTS = ("squint", "surprised", "crosseyed", "puff", "cringe", "scared", "angry", "pain", "shock")
# boxing-mode slots: file name -> slot in faces.json "boxing"
BOXING = {"hit_left": "left", "hit_right": "right", "uppercut": "up", "nose": "center",
          "wince": "wince", "dizzy": "dizzy", "ko": "ko", "taunt": "taunt"}


def has_alpha(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=pix_fmt",
                          "-of", "csv=p=0", path], capture_output=True, text=True).stdout.strip()
    return bool(re.search(r"rgba|bgra|argb|abgr|yuva|gbrap|ya8|ya16|pal8", out))


def main():
    args = sys.argv[1:]
    if len(args) < 2:
        print(__doc__); sys.exit(2)
    site, items, pain_override = args[0], [], None
    i = 1
    while i < len(args):
        if args[i] == "--pain":
            pain_override = [s for s in args[i + 1].split(",") if s]; i += 2; continue
        a = args[i]; i += 1
        if "=" in a and not os.path.exists(a):
            name, path = a.split("=", 1)
        else:
            path = a
            name = "base" if not items else re.sub(r"[^a-z0-9_]+", "_", os.path.splitext(os.path.basename(a))[0].lower()).strip("_") or f"face{len(items)}"
        if not os.path.isfile(path):
            print(f"找不到图片: {path}"); sys.exit(1)
        items.append((name, path))
    if items[0][0] != "base":
        items[0] = ("base", items[0][1])

    img = os.path.join(site, "img"); os.makedirs(img, exist_ok=True)
    names, warn = [], []
    for name, path in items:
        out = os.path.join(img, f"{name}.webp")
        if not has_alpha(path):
            warn.append(name)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", path, "-vf", "scale='min(900,iw)':-2",
                        "-c:v", "libwebp", "-pix_fmt", "yuva420p", "-quality", "86", out], check=True)
        names.append(name)
        print(f"  {name:<14} <- {path}")

    is_dmg = lambda n: re.fullmatch(r"dmg\d+(_hit_left|_hit_right|_ko)?", n)
    others = [n for n in names if n != "base" and n not in BOXING and not is_dmg(n)]
    pain = [n for n in others if (n in pain_override if pain_override is not None else any(h in n for h in PAIN_HINTS))]
    fun = [n for n in others if n not in pain]
    faces = {"base": "base.webp", "pain": [f"{n}.webp" for n in pain], "fun": [f"{n}.webp" for n in fun]}
    boxing = {BOXING[n]: f"{n}.webp" for n in names if n in BOXING}
    # injury stages dmg1..dmgN, each with its own idle / hit_left / hit_right so bruises never vanish mid-hit
    stages, k = [], 1
    while f"dmg{k}" in names:
        st = {"idle": f"dmg{k}.webp"}
        for side in ("left", "right"):
            if f"dmg{k}_hit_{side}" in names:
                st[side] = f"dmg{k}_hit_{side}.webp"
        stages.append(st); k += 1
    if stages:
        boxing["stages"] = stages
        if f"dmg{len(stages)}_ko" in names:
            boxing["ko"] = f"dmg{len(stages)}_ko.webp"
    if boxing:
        faces["boxing"] = boxing
    json.dump(faces, open(os.path.join(img, "faces.json"), "w"), indent=2, ensure_ascii=False)
    print(f"写入 {img}/faces.json  pain={pain}  fun={fun}  boxing={sorted(boxing)}")
    if warn:
        print(f"⚠️  这些图没有透明通道：{warn}。头像会带着背景方块被拉伸。"
              "请先抠图（或用 gen_faces.sh --photo 让接口出透明底），再重新运行本脚本。")


if __name__ == "__main__":
    main()

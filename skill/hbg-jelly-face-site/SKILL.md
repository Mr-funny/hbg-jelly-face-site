---
name: hbg-暴打boss
version: 1.1.0
display_name: "暴打boss：捏脸 + 拳击小游戏"
display_name_en: "HBG Beat Boss"
description_zh: "做一个网页小游戏：橙色圆盘里探出一个角色，可以把脸拽成果冻、松手回弹换表情；也可以玩 30 秒拳击挑战，打得越多脸越肿，打满 K.O.。角色可以用自己上传的表情图，也可以配置任意 OpenAI 兼容图像接口一键生成；一条命令发布到 GitHub Pages。"
description_en: "Build a browser mini-game: a character pops out of an orange disc. Pinch mode stretches the face like jelly and swaps expressions; boxing mode is a 30-second challenge where the face gets more bruised with every hit until K.O. Bring your own expression photos or generate them with any OpenAI-compatible image API, then publish to GitHub Pages."
description: 制作"暴打boss"网页小游戏（灵感来自 rameerez.com 的可拉扯头像）：左边是游戏标题和规则，右边橙色圆盘里探出一个抠好图的角色。两种模式：🤏 捏脸模式，用鼠标或手指把脸像太妃糖一样拉长，松手回弹并换表情；🥊 拳击挑战，30 秒限时出拳，左脸、右脸、下巴、鼻子各有不同反应，连击、暴击、晕眩星星、屏幕震动、合成音效，累计伤害让角色从毫发无伤一路变成面目全非并 K.O.，结束显示成绩和称号。three.js 网格 + 弹簧软体模拟，纯静态页面。角色图可以用户自己上传（透明背景 PNG 最好），也可以用用户自己配置的图像接口密钥（OpenAI 兼容：images/generations + images/edits）从一张照片或一句描述生成整套表情和四级伤势；密钥只从环境变量或 .env 读取，永远不写进页面和仓库。附带一键发布 GitHub Pages 的脚本（发布前扫描密钥）。当用户想做"拖拽变形的脸""果冻脸""打脸/拳击小游戏""把朋友或自己做成可以揍的网页""复刻 rameerez.com 头像效果"，或想把这种页面放上 GitHub Pages 时使用。
---

# HBG 暴打boss

一个网页小游戏，主角是一张能被拽、能被揍的脸。页面有两种模式，在角色下方切换：

- **🤏 捏脸模式**：抓住脸往外拽，像太妃糖一样拉长；松手后回弹并抖动，同时换表情。
- **🥊 拳击挑战**：30 秒限时游戏，看能打多少拳。
  - 打左脸颊、右脸颊、下巴（上勾拳）、鼻子，头往不同方向甩，表情也不同。
  - 快速连击会出现连击数、汗滴、暴击和晕眩星星。
  - 累计伤害越高，脸越肿：毫发无伤 → 轻微挂彩 → 鼻青脸肿 → 惨不忍睹 → 面目全非。打到最高一级会 K.O.。
  - 结束后有成绩、称号和本机最佳纪录。
  - 音效全部用 Web Audio 实时合成，可以静音。

整个页面是一个静态的 `index.html`，加上 `img/` 里的一组表情图和 `img/faces.json`，没有构建步骤。

模板自带示例角色（虚构、AI 生成）的全套 30 张图：中性脸、8 种捏脸表情、8 种拳击表情、4 级伤势各 3 张，以及 K.O.。

## 先问清楚（缺了就用默认值，别卡住）

1. **角色从哪来**（四选一）：
   - **A. 用示例角色**：`new_site.sh --demo`，什么都不用生成。
   - **B. 上传一张照片，用接口生成全套**：需要用户自己的图像接口密钥。
   - **C. 一句话描述一个虚构角色，用接口生成**：同样需要密钥。
   - **D. 自己准备好所有表情图**：直接导入，不需要密钥。
2. **游戏名和标语**：默认"暴打boss / 捏他、揍他，把他打成猪头。"
3. **主色**：默认橙色 `#f2470f` 配米色背景。
4. **要不要发布到 GitHub Pages**，仓库叫什么名字。

**真人照片**只能用用户本人的，或者用户明确说明有授权的。不要拿名人、公众人物或其他第三方的照片：拳击模式会把脸打成鼻青脸肿，用别人的脸就是在羞辱别人。用户用自己的照片时，提醒对方：发布到 GitHub Pages 后，这些照片和伤势图任何人都能看到。

## 密钥规则（必须遵守）

- 密钥**只**从这几处读取：环境变量 `JELLY_API_KEY`、站点目录下的 `.env`、`~/.config/hbg-jelly-face/.env`。模板的 `.gitignore` 已经忽略 `.env` 和 `raw/`。
- **不要**把密钥写进任何脚本、`index.html`、README、提交信息或对话总结。不要 `echo` 或 `cat` 含密钥的文件。
- 用户在聊天里直接贴了密钥时：只在当次命令里用环境变量传入（`JELLY_API_KEY=... bash gen_faces.sh ...`），或帮对方写进 `~/.config/hbg-jelly-face/.env`。之后提醒对方，密钥已经出现在聊天记录里，最好去控制台换一个新的。
- 页面运行时**不会**调用任何图像接口，所有图都是提前生成的静态文件。所以发布出去的页面里不存在密钥。
- 配置格式见 [references/api-config.md](references/api-config.md)。

## 工作流程

```bash
bash <skill>/scripts/new_site.sh <站点目录>          # 复制模板（加 --demo 会带上示例 Leo）
```

**A. 用户自己的图**

```bash
python3 <skill>/scripts/prepare_faces.py <站点目录> base=中性.png grin=大笑.png squint=挤眼.png ...
# 也可以不写名字：第一张当 base，其余按文件名命名
# --pain a,b   手动指定"被拽时"显示哪几张
```

这一步把图缩放成 900px 宽的 WebP（保留透明），并写好 `img/faces.json`。

- 脚本提示某张"没有透明通道"时：头像会带着方形背景一起被拉伸，效果很差。让用户先抠图，或者有密钥的话走 B 流程。
- 只有一张图也能用：果冻效果照常，只是不换表情。

**B / C. 用接口生成**

```bash
bash <skill>/scripts/gen_faces.sh <站点目录> --prompt "一个虚构的年轻人，短卷发，穿深色T恤"   # C
bash <skill>/scripts/gen_faces.sh <站点目录> --photo 我的照片.jpg                          # B
#   --set pinch | boxing | damage | all       选择要生成的表情组（默认 pinch，即捏脸用的 8 种）
#       boxing：hit_left、hit_right、uppercut、nose、wince、dizzy、ko、taunt
#       damage：dmg1–4 四级伤势（链式生成，每一级在上一级基础上加伤），
#               每级再生成 hit_left / hit_right，最后一级加 ko
#   --expressions grin,squint,surprised,...   自定义表情列表，未知名字会当作英文描述
#   --skip-base                               沿用已有的 raw/base.png，只重生表情
```

- 先生成或抠出一张透明底的中性脸 `raw/base.png`，再以它为底图用 edits 接口并行改出每种表情。这样身份、发型、机位都能保持一致。
- 生成完会自动调用 `prepare_faces.py`。
- 完整一套是 `--set all`，大约 29 张图。也可以分几次跑：`gen_faces.sh` 每次都会把 `raw/` 里已有的图一起重新整理，之前生成的不会丢。
- 伤势图只做喜剧效果的淤青、肿包和创可贴，提示词里已经写明不要血和伤口，不要改成写实血腥风格。
- 拳击模式里缺哪张图都能运行：缺 boxing 组就用 pain 表情代替，缺 damage 组就没有伤势升级。
- **一定要看一遍 `raw/` 里的图**。某张表情走样（换了人、位置偏了、背景不透明）时，删掉它，用 `--skip-base --expressions <那几个>` 单独重生。

**改文字和颜色**：`index.html` 里标了 `<!-- EDIT: ... -->` 和 `/* EDIT: colors */` 的地方，包括游戏名、标语、规则和页脚。

**换角色**：先把旧的 `raw/` 改名备份（`mv raw raw-旧角色`），否则旧角色的图会混进新的 `faces.json`。然后重新生成：`gen_faces.sh <站点> --photo 照片.jpg --set all`。

**本地预览**：`python3 -m http.server 8801 --directory <站点目录>`。不能直接双击打开 `index.html`：`fetch` 和 ES module 在 `file://` 下用不了。

**调手感**：看 [references/tuning.md](references/tuning.md)。

**发布到 GitHub Pages**

```bash
bash <skill>/scripts/deploy_pages.sh <站点目录> <仓库名>
```

- 需要已经登录的 `gh`。发布前会扫描像密钥的字符串，发现就拒绝发布。
- 只提交 `index.html`、`img/`、`.gitignore` 和 README。
- 首次开启 Pages 后要等 1–2 分钟。
- 创建公开仓库属于对外发布，执行前跟用户确认仓库名和公开范围（用户已经明确说过"发布到 GitHub Pages"时，可以视为已同意）。

## 交付前检查

逐条过一遍 [references/quality-gate.md](references/quality-gate.md)。

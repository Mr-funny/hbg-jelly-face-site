# 图像接口配置

`gen_faces.sh` 支持任意 **OpenAI 兼容**的图像接口，需要提供这两个端点：

- `POST {BASE}/images/generations`：文字生成图片（C 流程的中性脸）
- `POST {BASE}/images/edits`：以图改图（B 流程的抠图，以及所有表情）

请求时固定使用 `size=1024x1024`、`background=transparent`、`output_format=png`。返回 `b64_json` 或 `url` 都能处理。

## 三个变量

| 变量 | 说明 | 默认值 |
|---|---|---|
| `JELLY_API_KEY` | 接口密钥（必填） | — |
| `JELLY_API_BASE` | 接口地址，以 `/v1` 结尾 | `https://api.openai.com/v1` |
| `JELLY_IMAGE_MODEL` | 图像模型 | `gpt-image-1` |

## 读取优先级

1. 当前进程的环境变量（最高）
2. `<站点目录>/.env`
3. `~/.config/hbg-jelly-face/.env`

推荐写进 `~/.config/hbg-jelly-face/.env`：配一次，所有站点都能用，而且这个文件不在任何仓库里。

```bash
mkdir -p ~/.config/hbg-jelly-face
cat > ~/.config/hbg-jelly-face/.env <<'EOF'
JELLY_API_KEY=你的密钥
JELLY_API_BASE=https://你的服务地址/v1
JELLY_IMAGE_MODEL=gpt-image-2
EOF
chmod 600 ~/.config/hbg-jelly-face/.env
```

## 防泄露措施

- 密钥通过 `curl -K -`（从标准输入读配置）传给 curl，不会出现在 `ps` 进程列表或命令行历史里。
- 脚本只打印"密钥：已配置（不显示）"。
- `.env` 和 `raw/` 都在模板的 `.gitignore` 里。
- `deploy_pages.sh` 发布前会用正则扫描 `sk-…`、`Bearer …`、`JELLY_API_KEY=…` 以及 40 位以上的十六进制串，命中就中止发布。
- 页面运行时不调用接口，所以公开页面里没有密钥。

## 常见报错

- `FAIL ... model not found`：服务上没有这个模型。改 `JELLY_IMAGE_MODEL`，可用模型可以访问 `{BASE}/models` 查看。
- 返回的图背景不透明：有的模型不支持 `background=transparent`。换支持透明背景的模型，或者先手动抠图，再用 `prepare_faces.py` 导入。
- Python 报 `CERTIFICATE_VERIFY_FAILED`：脚本所有网络请求都走 curl，不受影响。

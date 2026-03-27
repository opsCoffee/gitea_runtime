# LaTeX 文档处理运行时

## 定位

用于 LaTeX 文档编译与中文排版，适合需要 `xelatex`、TinyTeX 和 Node.js 的任务。

## 镜像信息

| 项目 | 值 |
| --- | --- |
| 基础镜像 | `node:20.17.0-bookworm-slim` |
| 默认用户 | `appuser` |
| 工作目录 | `/app` |
| 默认命令 | `bash -c "xelatex --version && echo 'TinyTeX is ready!'"` |
| 关键工具 | `xelatex`, `tlmgr`, `node` |

## 构建

```bash
docker buildx build -t gitea-runtime-latex:latest ./runtime-latex
./scripts/runtimectl.sh build --only latex
```

如需对 TinyTeX 安装脚本启用完整性校验，可传入：

```bash
docker buildx build \
  --build-arg TINYTEX_INSTALLER_SHA256=<sha256> \
  -t gitea-runtime-latex:latest \
  ./runtime-latex
```

## 最小验证

```bash
./scripts/runtimectl.sh test --only latex
```

## 常用用法

```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-latex:latest xelatex document.tex

docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-latex:latest node script.js
```

## 在 Gitea Actions 中使用

```yaml
jobs:
  latex-build:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-latex:latest
    steps:
      - uses: actions/checkout@v4
      - run: xelatex document.tex
```

## 预装工具与环境

- 环境变量：`DEBIAN_FRONTEND`、`LANG`、`LANGUAGE`、`LC_ALL`、`TZ`
- 运行工具：`xelatex`、`tlmgr`、`node`
- 字体与中文支持：`fonts-liberation`、`fonts-noto-cjk`、`xecjk`、`ctex`

## 安全与维护

- 以非 root 用户 `appuser` 运行
- TinyTeX 安装链路采用“下载到文件 -> 可选校验 -> 显式执行”
- Dockerfile 风格维护遵循 [docs/DOCKERFILE_STYLE.md](../docs/DOCKERFILE_STYLE.md)

# Markdown 格式化运行时

## 定位

用于 Markdown 文档检查与格式验证，适合在 Gitea Actions 或本地容器里执行 `markdownlint-cli2`。

## 镜像信息

| 项目 | 值 |
| --- | --- |
| 基础镜像 | `node:lts-alpine3.20` |
| 默认用户 | `appuser` |
| 工作目录 | `/app` |
| 默认命令 | `bash` |
| 关键工具 | `markdownlint-cli2`, `node`, `python3` |

## 构建

```bash
docker buildx build -t gitea-runtime-markdown:latest ./runtime-markdown
./scripts/runtimectl.sh build --only markdown
```

## 最小验证

```bash
./scripts/runtimectl.sh test --only markdown
```

## 常用用法

```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-markdown:latest markdownlint-cli2 README.md

docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-markdown:latest markdownlint-cli2 --fix README.md
```

## 在 Gitea Actions 中使用

```yaml
jobs:
  markdown-lint:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-markdown:latest
    steps:
      - uses: actions/checkout@v4
      - run: markdownlint-cli2 "**/*.md"
```

## 预装工具与环境

- 环境变量：`LANG`、`LANGUAGE`、`LC_ALL`、`TZ`
- 运行工具：`markdownlint-cli2`、`node`、`python3`
- 辅助工具：`bash`、`curl`、`git`、`vim`、`dos2unix`、`perl`

## 安全与维护

- 以非 root 用户 `appuser` 运行
- 安装链路不再使用远程脚本管道直连执行
- Dockerfile 风格维护遵循 [docs/DOCKERFILE_STYLE.md](../docs/DOCKERFILE_STYLE.md)

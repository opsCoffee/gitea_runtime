# 安全模板处理运行时

## 定位

用于 Nuclei 模板验证、模板校验和与安全模板相关的自动化任务。

## 镜像信息

| 项目 | 值 |
| --- | --- |
| 基础镜像 | `node:22.6.0-alpine` |
| 默认用户 | `appuser` |
| 工作目录 | `/app` |
| 默认命令 | `bash` |
| 关键工具 | `nuclei`, `generate-checksum` |

## 构建

```bash
docker buildx build -t gitea-runtime-template:latest ./runtime-template
./scripts/runtimectl.sh build --only template
```

## 最小验证

```bash
./scripts/runtimectl.sh test --only template
```

## 常用用法

```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-template:latest nuclei -validate -t templates

docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-template:latest generate-checksum -d templates
```

## 在 Gitea Actions 中使用

```yaml
jobs:
  template-validate:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-template:latest
    steps:
      - uses: actions/checkout@v4
      - run: nuclei -validate -t templates
```

## 预装工具与环境

- 环境变量：`LANG`、`LANGUAGE`、`LC_ALL`、`TZ`
- 运行工具：`nuclei`、`generate-checksum`
- 辅助工具：`bash`、`curl`、`git`、`python3`、`tree`

## 安全与维护

- 以非 root 用户 `appuser` 运行
- 采用多阶段构建，仅复制最终需要的二进制
- Dockerfile 风格维护遵循 [docs/DOCKERFILE_STYLE.md](../docs/DOCKERFILE_STYLE.md)

# ASUSTOR 应用运行时

## 定位

用于 ASUSTOR 或轻量 NAS 相关脚本运行，适合同时需要 Python 与 Node.js 的任务。

## 镜像信息

| 项目 | 值 |
| --- | --- |
| 基础镜像 | `alpine:3.20` |
| 默认用户 | `root` |
| 工作目录 | `/app` |
| 默认命令 | `sh` |
| 关键工具 | `python3`, `nodejs`, `npm`, `git` |

## 构建

```bash
docker buildx build -t gitea-runtime-asustor:latest ./runtime-asustor
./scripts/runtimectl.sh build --only asustor
```

## 最小验证

```bash
./scripts/runtimectl.sh test --only asustor
```

## 常用用法

```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-asustor:latest python3 script.py

docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-asustor:latest node index.js
```

## 在 Gitea Actions 中使用

```yaml
jobs:
  asustor-script:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-asustor:latest
    steps:
      - uses: actions/checkout@v4
      - run: python3 script.py
```

## 预装工具与环境

- 环境变量：`LANG`、`LANGUAGE`、`LC_ALL`、`TZ`、`PYTHONUNBUFFERED`
- 运行工具：`python3`、`nodejs`、`npm`
- 辅助工具：`git`、`tzdata`

## 安全与维护

- **必须以 root 用户运行**：ASUSTOR 脚本通常需要系统级权限（如安装依赖、修改配置文件），使用非 root 用户会导致 Gitea Actions workflow 因权限不足而中断
- 镜像保持单阶段、轻量化结构
- Dockerfile 风格维护遵循 [docs/DOCKERFILE_STYLE.md](../docs/DOCKERFILE_STYLE.md)

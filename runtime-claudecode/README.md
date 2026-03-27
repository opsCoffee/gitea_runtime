# Claude Code 开发环境

## 定位

用于 Claude Code CLI、MCP 服务器和 Git hook 相关的开发任务。

## 镜像信息

| 项目 | 值 |
| --- | --- |
| 基础镜像 | `node:22.6.0-alpine` |
| 默认用户 | `nextjs` |
| 工作目录 | `/app` |
| 默认命令 | `bash` |
| 关键工具 | `claude`, `git`, `install-claude-git-hook` |

## 构建

```bash
docker buildx build -t gitea-runtime-claudecode:latest ./runtime-claudecode
./scripts/runtimectl.sh build --only claudecode
```

## 最小验证

```bash
./scripts/runtimectl.sh test --only claudecode
```

## 常用用法

```bash
docker run -it --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-claudecode:latest claude

docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-claudecode:latest install-claude-git-hook /workspace
```

## 在 Gitea Actions 中使用

```yaml
jobs:
  claude-task:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-claudecode:latest
    steps:
      - uses: actions/checkout@v4
      - run: claude --version
```

## 预装工具与环境

- 环境变量：`LANG`、`LANGUAGE`、`LC_ALL`、`TZ`
- 运行工具：`claude`、`git`、`bash`
- 辅助工具：`curl`、`vim`、`openssh-client`、`rsync`
- Claude 配置目录：`/home/nextjs/.claude`

## 补充说明

- 镜像内预配置了 `context7`、`grep`、`deepwiki`、`sequential-thinking` MCP 服务
- `install-claude-git-hook` 会把模板安装到目标仓库的 `.git/hooks/prepare-commit-msg`

## 安全与维护

- 以非 root 用户 `nextjs` 运行
- Git hook 模板在运行时安装，不依赖构建阶段宿主仓库
- Dockerfile 风格维护遵循 [docs/DOCKERFILE_STYLE.md](../docs/DOCKERFILE_STYLE.md)

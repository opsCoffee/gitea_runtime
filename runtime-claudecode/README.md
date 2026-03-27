# Claude Code 开发环境

## 概述

这个 Docker 镜像提供了一个完整的 Claude Code 开发环境，集成了 Claude Code CLI 工具和多个 MCP（Model Context Protocol）服务器。它基于 Node.js 22 Alpine 镜像，专为使用 Claude Code 进行 AI 辅助开发而设计。

## 特点

- 基于 Node.js 22 Alpine 的轻量级镜像
- 预装 Claude Code CLI 工具（版本 2.0.26）
- 集成多个 MCP 服务器：Context7、Grep、DeepWiki、Sequential Thinking
- 内置 Git 提交钩子模板与运行时安装脚本
- 预配置 Git 设置（中文支持、rebase 策略）
- 使用非 root 用户运行，增强安全性
- 包含常用开发工具：rsync、bash、curl、vim 等

## 构建镜像

使用以下命令构建镜像：

```bash
docker buildx build -t gitea-runtime-claudecode:latest -f runtime-claudecode/Dockerfile .
```

或者使用统一脚本入口：

```bash
./scripts/runtimectl.sh build --only claudecode
```

## 使用方法

### 基本用法

```bash
docker run --rm gitea-runtime-claudecode:latest claude --version
```

### 最小功能测试

```bash
docker run -it --rm -v $(pwd):/app -w /app gitea-runtime-claudecode:latest install-claude-git-hook /app
```

### 启动 Claude Code 交互式会话

```bash
docker run -it --rm gitea-runtime-claudecode:latest claude
```

### 在项目目录中使用 Claude Code

```bash
docker run -it --rm -v $(pwd):/app -w /app gitea-runtime-claudecode:latest claude
```

### 安装 Git 提交钩子

镜像会保留 `prepare-commit-msg` hook 模板，但不会在构建阶段假设宿主仓库已存在。若需要在当前项目中安装 hook，可在容器内执行：

```bash
docker run -it --rm -v $(pwd):/app -w /app gitea-runtime-claudecode:latest install-claude-git-hook /app
```

### 使用特定 MCP 服务器

```bash
docker run -it --rm -v $(pwd):/app -w /app gitea-runtime-claudecode:latest claude --mcp context7
```

## MCP 服务器配置

镜像中预配置了以下 MCP 服务器：

1. **Context7**: 提供上下文理解和文档搜索
   - 类型: HTTP
   - 端点: https://mcp.context7.com/mcp

2. **Grep**: 提供代码搜索功能
   - 类型: HTTP  
   - 端点: https://mcp.grep.app

3. **DeepWiki**: 提供深度知识库访问
   - 类型: HTTP
   - 端点: https://mcp.deepwiki.com/mcp

4. **Sequential Thinking**: 提供顺序思维推理
   - 类型: 本地命令
   - 命令: npx -y @modelcontextprotocol/server-sequential-thinking

## 在 Gitea Actions 中使用

```yaml
name: AI 辅助代码审查

on:
  pull_request:
    branches: [ main ]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-claudecode:latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: 使用 Claude Code 进行代码审查
        run: |
          # 按需安装 Git 提交钩子
          install-claude-git-hook "$PWD"
          
          # 运行 Claude Code 进行代码分析
          claude analyze --diff HEAD~1..HEAD
```

## 环境变量

- `LANG=en_US.UTF-8`: 设置系统语言为英文 UTF-8 编码
- `LANGUAGE=en_US.UTF-8`: 设置语言环境
- `LC_ALL=en_US.UTF-8`: 设置所有本地化参数
- `TZ=Asia/Shanghai`: 设置时区为亚洲/上海

## Git 配置

镜像中预配置了以下 Git 设置：

- `pull.rebase true`: 拉取时使用 rebase 策略
- `core.quotepath false`: 支持中文文件名显示
- `i18n.commitencoding utf-8`: 提交信息使用 UTF-8 编码
- `i18n.logoutputencoding utf-8`: 日志输出使用 UTF-8 编码

## 已安装工具

### 主要工具
- Node.js 22
- Claude Code CLI (v2.0.26)
- MCP 服务器工具

### 辅助工具
- rsync
- bash
- curl
- vim
- git
- openssh-client
- tzdata
- dos2unix

## 安全性

- 使用非 root 用户 `nextjs` 运行
- 定期更新基础镜像和依赖
- MCP 服务器使用 HTTPS 连接
- 包含健康检查配置

## 自定义配置

可以通过挂载配置文件来自定义 Claude Code 设置：

```bash
docker run -it --rm \
  -v $(pwd):/app \
  -v $(pwd)/.claude-config:/home/nextjs/.claude \
  -w /app \
  gitea-runtime-claudecode:latest claude
```

## 维护

如有问题或建议，请提交 issue 或 pull request。

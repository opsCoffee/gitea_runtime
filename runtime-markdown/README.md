# Markdown 格式化运行时

## 概述

这个 Docker 镜像提供了一个轻量级的 Markdown 文档格式化和检查环境，专为 Gitea Runner 设计。它包含了 `markdownlint-cli2` 工具，可以用于检查和格式化 Markdown 文件，确保文档符合标准格式。

## 特点

- 基于 Alpine Linux 的轻量级镜像
- 预装 Node.js LTS 版本
- 包含 markdownlint-cli2 工具
- 支持 Python 3 环境
- 包含常用工具：bash、curl、git、vim、dos2unix、perl
- 使用非 root 用户运行，增强安全性
- 多阶段构建，优化镜像大小

## 构建镜像

使用以下命令构建镜像：

```bash
docker buildx build -t gitea-runtime-markdown:latest -f runtime-markdown/Dockerfile .
```

或者使用项目根目录的 `build.sh` 脚本：

```bash
./build.sh --only markdown
```

## 使用方法

### 基本用法

```bash
docker run --rm gitea-runtime-markdown:latest markdownlint-cli2 --version
```

### 检查 Markdown 文件

```bash
docker run --rm -v $(pwd):/app gitea-runtime-markdown:latest markdownlint-cli2 /app/README.md
```

### 格式化 Markdown 文件

```bash
docker run --rm -v $(pwd):/app gitea-runtime-markdown:latest markdownlint-cli2 --fix /app/README.md
```

## 在 Gitea Actions 中使用

```yaml
name: Markdown Lint

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-markdown:latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Lint Markdown files
        run: |
          markdownlint-cli2 "**/*.md"
```

## 环境变量

- `LANG=en_US.utf8`: 设置系统语言为英文 UTF-8 编码

## 已安装工具

- Node.js (LTS 版本)
- markdownlint-cli2
- Python 3
- bash
- curl
- git
- vim
- dos2unix
- perl

## 安全性

- 使用非 root 用户 `appuser` 运行
- 定期更新基础镜像和依赖
- 移除不必要的工具和文件，减小攻击面

## 维护

如有问题或建议，请提交 issue 或 pull request。
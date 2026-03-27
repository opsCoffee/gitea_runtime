# LaTeX 文档处理运行时

## 概述

这个 Docker 镜像提供了一个集成了 TinyTeX 和 Node.js 环境的运行时，适用于需要同时使用 LaTeX 和 Node.js 的项目。镜像通过多阶段构建，确保最终镜像尽可能小，同时保留完整的 LaTeX 文档处理功能。

## 特点

- 基于 Node.js 20 的轻量级镜像
- 集成精简版 TinyTeX 环境
- 预装常用 LaTeX 宏包
- 多阶段构建，优化镜像大小
- 使用非 root 用户运行，增强安全性
- 使用 TinyTeX 官方安装脚本“下载到文件 → 可选 SHA256 校验 → 显式执行”的安装链路，避免远程脚本管道直连执行
- 使用清华大学 CTAN 镜像源加速包安装

## 构建镜像

如需对 TinyTeX 安装脚本启用完整性校验，可在构建时传入 `TINYTEX_INSTALLER_SHA256`：

```bash
docker buildx build \
  --build-arg TINYTEX_INSTALLER_SHA256=<sha256> \
  -t gitea-runtime-latex:latest \
  -f runtime-latex/Dockerfile .
```

未提供该参数时，Dockerfile 会明确输出跳过校验的提示。


使用以下命令构建镜像：

```bash
docker buildx build -t gitea-runtime-latex:latest -f runtime-latex/Dockerfile .
```

或者使用统一脚本入口：

```bash
./scripts/runtimectl.sh build --only latex
```

## 使用方法

### 基本用法

```bash
docker run --rm gitea-runtime-latex:latest xelatex --version
```

### 编译 LaTeX 文档

```bash
docker run --rm -v $(pwd):/app gitea-runtime-latex:latest xelatex /app/document.tex
```

### 使用 Node.js

```bash
docker run --rm -v $(pwd):/app gitea-runtime-latex:latest node /app/script.js
```

### 交互式 Shell

```bash
docker run -it --rm gitea-runtime-latex:latest bash
```

## 在 Gitea Actions 中使用

```yaml
name: LaTeX Document Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-latex:latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Build LaTeX document
        run: |
          xelatex document.tex
          xelatex document.tex  # 运行两次以生成目录和引用
      
      - name: Upload PDF
        uses: actions/upload-artifact@v3
        with:
          name: document
          path: document.pdf
```

## 环境变量

- `DEBIAN_FRONTEND=noninteractive`: 禁用交互式提示
- `PATH`: 包含 TinyTeX 可执行文件路径

## 已安装的 LaTeX 宏包

- enumitem
- titlesec
- fontawesome5
- parskip
- ctex
- fandol

## 安全性

- 使用非 root 用户 `node` 运行
- 定期更新基础镜像和依赖
- TinyTeX 安装脚本采用“下载、可选校验、显式执行”的链路，便于后续接入固定 hash
- 移除不必要的文档、源文件和缓存

## 维护

如有问题或建议，请提交 issue 或 pull request。

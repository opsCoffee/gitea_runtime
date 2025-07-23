# LaTeX 文档处理运行时

## 概述

这个 Docker 镜像提供了一个集成了 TinyTeX 和 Node.js 环境的运行时，适用于需要同时使用 LaTeX 和 Node.js 的项目。镜像通过多阶段构建，确保最终镜像尽可能小，同时保留完整的 LaTeX 文档处理功能。

## 特点

- 基于 Node.js 20 的轻量级镜像
- 集成精简版 TinyTeX 环境
- 预装常用 LaTeX 宏包
- 多阶段构建，优化镜像大小
- 使用非 root 用户运行，增强安全性
- 使用清华大学 CTAN 镜像源加速包安装

## 构建镜像

使用以下命令构建镜像：

```bash
docker buildx build -t gitea-runtime-latex:latest -f runtime-latex/Dockerfile .
```

或者使用项目根目录的 `build.sh` 脚本：

```bash
./build.sh --only latex
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
- 移除不必要的文档、源文件和缓存

## 维护

如有问题或建议，请提交 issue 或 pull request。
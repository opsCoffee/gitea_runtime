# ASUSTOR 应用运行时

## 概述

这个 Docker 镜像提供了一个轻量级的运行环境，专为 ASUSTOR NAS 设备相关的应用开发和测试设计。它基于 Alpine Linux，包含了 Python 3、Node.js、npm 和 git 等基本工具。

## 特点

- 基于 Alpine Linux 3.20 的超轻量级镜像
- 预装 Python 3 环境
- 包含 Node.js 和 npm
- 内置 git 支持
- 使用非 root 用户运行，增强安全性
- 镜像体积小，启动速度快

## 构建镜像

使用以下命令构建镜像：

```bash
docker buildx build -t gitea-runtime-asustor:latest -f runtime-asustor/Dockerfile .
```

或者使用项目根目录的 `build.sh` 脚本：

```bash
./build.sh --only asustor
```

## 使用方法

### 基本用法

```bash
docker run --rm gitea-runtime-asustor:latest python3 --version
```

### 运行 Python 脚本

```bash
docker run --rm -v $(pwd):/app gitea-runtime-asustor:latest python3 /app/script.py
```

### 运行 Node.js 应用

```bash
docker run --rm -v $(pwd):/app gitea-runtime-asustor:latest node /app/index.js
```

### 交互式 Shell

```bash
docker run -it --rm gitea-runtime-asustor:latest
```

## 在 Gitea Actions 中使用

```yaml
name: ASUSTOR App Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-asustor:latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run tests
        run: |
          python3 tests/run_tests.py
```

## 环境变量

- `LANG=en_US.UTF-8`: 设置系统语言为英文 UTF-8 编码
- `PYTHONUNBUFFERED=1`: 确保 Python 输出不被缓冲，便于日志记录

## 已安装工具

- Python 3
- Node.js
- npm
- git

## 安全性

- 使用非 root 用户 `appuser` 运行
- 定期更新基础镜像和依赖
- 移除不必要的缓存和临时文件

## 维护

如有问题或建议，请提交 issue 或 pull request。
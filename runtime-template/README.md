# 安全模板处理运行时

## 概述

这个 Docker 镜像提供了一个专门用于安全模板处理和验证的环境，特别是与 Nuclei 工具相关的操作。它基于 Node.js 镜像，并包含了从 Go 构建的 Nuclei 工具链，适用于安全扫描模板的开发、测试和验证。

## 特点

- 基于 Node.js 22 Alpine 的轻量级镜像
- 预装 Nuclei 安全扫描工具
- 包含 generate-checksum 工具
- 多阶段构建，优化镜像大小
- 使用非 root 用户运行，增强安全性
- 包含常用工具：bash、curl、git、python3、vim、dos2unix 等

## 构建镜像

使用以下命令构建镜像：

```bash
docker buildx build -t gitea-runtime-template:latest -f runtime-template/Dockerfile .
```

或者使用项目根目录的 `build.sh` 脚本：

```bash
./build.sh --only template
```

## 使用方法

### 基本用法

```bash
docker run --rm gitea-runtime-template:latest nuclei -version
```

### 运行 Nuclei 扫描

```bash
docker run --rm -v $(pwd):/app gitea-runtime-template:latest nuclei -t /app/templates -u https://example.com
```

### 生成模板校验和

```bash
docker run --rm -v $(pwd):/app gitea-runtime-template:latest generate-checksum -d /app/templates
```

### 运行自定义模板扫描

```bash
docker run --rm -v $(pwd):/app gitea-runtime-template:latest nuclei -t /app/custom-templates -u https://example.com
```

### 交互式 Shell

```bash
docker run -it --rm gitea-runtime-template:latest
```

## 在 Gitea Actions 中使用

```yaml
name: Security Template Validation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-template:latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate templates
        run: |
          generate-checksum -d templates
          nuclei -validate -t templates
```

## 环境变量

- `LANG=en_US.UTF-8`: 设置系统语言为英文 UTF-8 编码
- `LANGUAGE=en_US.UTF-8`: 设置语言环境
- `LC_ALL=en_US.UTF-8`: 设置所有本地化参数

## 已安装工具

### 主要工具
- Node.js 22
- Nuclei
- generate-checksum

### 辅助工具
- Python 3
- pip
- bash
- curl
- vim
- git
- dos2unix
- tree

## 安全性

- 使用非 root 用户 `appuser` 运行
- 定期更新基础镜像和依赖
- 移除不必要的缓存和临时文件

## 维护

如有问题或建议，请提交 issue 或 pull request。
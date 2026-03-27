# 基础 Node.js 运行时

## 概述

这个 Docker 镜像提供了一个基础的 Node.js 运行时环境，包含常用的开发工具。它基于 Node.js 22 Alpine 镜像，适合作为其他运行时环境的基础镜像，也可以直接用于 Node.js 应用的开发和测试。

## 特点

- 基于 Node.js 22 Alpine 的轻量级镜像
- 包含常用开发工具：bash、curl、vim、git、openssh-client
- 预配置时区设置（亚洲/上海）
- 使用非 root 用户运行，增强安全性
- 包含健康检查配置
- 遵循 OCI 标准标签规范

## 构建镜像

使用以下命令构建镜像：

```bash
docker buildx build -t gitea-runtime-base:latest -f runtime-base/Dockerfile .
```

或者使用统一脚本入口：

```bash
./scripts/runtimectl.sh build --only base
```

## 使用方法

### 基本用法

```bash
docker run --rm gitea-runtime-base:latest node --version
```

### 最小功能测试

```bash
docker run --rm -v $(pwd):/app -w /app gitea-runtime-base:latest node index.js
```

### 运行 Node.js 应用

```bash
docker run --rm -v $(pwd):/app gitea-runtime-base:latest node /app/index.js
```

### 使用 npm 安装依赖

```bash
docker run --rm -v $(pwd):/app -w /app gitea-runtime-base:latest npm install
```

### 交互式 Shell

```bash
docker run -it --rm gitea-runtime-base:latest bash
```

## 在 Gitea Actions 中使用

```yaml
name: Node.js 应用测试

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-base:latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: 安装依赖
        run: npm install
      
      - name: 运行测试
        run: npm test
      
      - name: 构建应用
        run: npm run build
```

## 环境变量

- `LANG=en_US.UTF-8`: 设置系统语言为英文 UTF-8 编码
- `LANGUAGE=en_US.UTF-8`: 设置语言环境
- `LC_ALL=en_US.UTF-8`: 设置所有本地化参数
- `TZ=Asia/Shanghai`: 设置时区为亚洲/上海

## 已安装工具

### 主要工具
- Node.js 22
- npm

### 辅助工具
- bash
- curl
- vim
- git
- openssh-client
- tzdata

## 安全性

- 使用非 root 用户 `nextjs` 运行
- 遵循 OCI 标准标签规范
- 定期更新基础镜像和依赖
- 包含健康检查配置

## 作为基础镜像

这个镜像可以作为其他运行时环境的基础镜像使用：

```dockerfile
FROM gitea-runtime-base:latest

# 添加特定工具
RUN apk add --no-cache your-tool

# 切换到非 root 用户
USER nextjs
```

## 维护

如有问题或建议，请提交 issue 或 pull request。

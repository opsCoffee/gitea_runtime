# Maven Java 构建环境

## 概述

这个 Docker 镜像提供了一个完整的 Maven Java 构建环境，集成了 BellSoft Liberica JDK 17 和 Maven 构建工具。它基于 Debian Slim 镜像，专为 Java 项目的构建、测试和部署而设计。

## 特点

- 基于 BellSoft Liberica JDK 17 的稳定 Java 环境
- 预装固定版本的 Maven 构建工具（默认 3.9.12）
- 包含 Node.js 20 和 npm，支持全栈项目构建
- 下载并校验固定版本的 Maven 发行包，提升构建可重现性
- 通过显式 NodeSource keyring 仓库配置安装 Node.js 20，避免远程脚本直连执行
- 包含常用构建工具：curl、git、bash、ca-certificates
- 支持 JavaFX 项目开发
- 使用 UTF-8 编码环境

## 构建镜像

使用以下命令构建镜像：

```bash
docker buildx build -t gitea-runtime-maven:latest -f runtime-maven/Dockerfile .
```

或者使用统一脚本入口：

```bash
./scripts/runtimectl.sh build --only maven
```

## 使用方法

### 基本用法

```bash
docker run --rm gitea-runtime-maven:latest mvn --version
```

### 最小功能测试

```bash
docker run --rm -v $(pwd):/workspace -w /workspace gitea-runtime-maven:latest \
  mvn -q -DskipTests help:evaluate -Dexpression=project.artifactId -DforceStdout
```

### 构建 Java 项目

```bash
docker run --rm -v $(pwd):/workspace -w /workspace gitea-runtime-maven:latest mvn clean package
```

### 运行测试

```bash
docker run --rm -v $(pwd):/workspace -w /workspace gitea-runtime-maven:latest mvn test
```

### 安装依赖

```bash
docker run --rm -v $(pwd):/workspace -w /workspace gitea-runtime-maven:latest mvn dependency:resolve
```

### 交互式 Shell

```bash
docker run -it --rm -v $(pwd):/workspace -w /workspace gitea-runtime-maven:latest bash
```

## 在 Gitea Actions 中使用

```yaml
name: Java 项目构建

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-maven:latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: 编译项目
        run: mvn clean compile
      
      - name: 运行测试
        run: mvn test
      
      - name: 打包项目
        run: mvn package -DskipTests
      
      - name: 上传构建产物
        uses: actions/upload-artifact@v3
        with:
          name: target
          path: target/*.jar
```

## 环境变量

- `LANG=C.UTF-8`: 设置系统语言为 C.UTF-8 编码
- `PATH`: 包含 Java 和 Maven 可执行文件路径

## 已安装工具

### 主要工具
- BellSoft Liberica JDK 17 (含 JavaFX)
- Maven 3.9.12
- Node.js 20
- npm (最新版本)

### 辅助工具
- curl
- git
- bash
- ca-certificates
- gnupg
- xz-utils
- tar

## Maven 配置

镜像中的 Maven 默认固定为 3.9.12，并在构建时对下载的发行包执行 SHA512 校验，以提升可验证性与可重现性。Maven 本地仓库默认位于 `/home/appuser/.m2`。

### 自定义 Maven 配置

可以通过挂载自定义的 `settings.xml` 文件来配置 Maven：

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/settings.xml:/home/appuser/.m2/settings.xml \
  -w /workspace \
  gitea-runtime-maven:latest mvn clean package
```

## Java 特性支持

- **Java 17 特性**: 完整支持 Java 17 的所有语言特性
- **JavaFX**: 内置 JavaFX 支持，可直接构建 GUI 应用
- **模块化**: 支持 Java 模块系统 (JPMS)
- **记录类**: 支持 Java 14+ 的记录类特性

## 性能优化

### JVM 参数配置

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  -e MAVEN_OPTS="-Xmx2g -XX:+UseG1GC" \
  gitea-runtime-maven:latest mvn clean package
```

### 并行构建

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  gitea-runtime-maven:latest mvn -T 1C clean package
```

## 安全性

- 使用官方 BellSoft Liberica JDK 镜像
- 定期更新基础镜像和依赖
- 包含完整的证书链验证
- 支持 HTTPS 仓库访问

## 故障排除

### 常见问题

1. **Maven 下载缓慢**
   ```bash
   # 使用国内镜像源
   docker run --rm \
     -v $(pwd):/workspace \
     -v $(pwd)/settings.xml:/root/.m2/settings.xml \
     -w /workspace \
     gitea-runtime-maven:latest mvn clean package
   ```

2. **Java 版本不兼容**
   ```bash
   # 检查 Java 版本
   docker run --rm gitea-runtime-maven:latest java -version
   ```

3. **内存不足**
   ```bash
   # 增加 Maven 内存限制
   docker run --rm \
     -v $(pwd):/workspace \
     -w /workspace \
     -e MAVEN_OPTS="-Xmx4g" \
     gitea-runtime-maven:latest mvn clean package
   ```

## 维护

如有问题或建议，请提交 issue 或 pull request。

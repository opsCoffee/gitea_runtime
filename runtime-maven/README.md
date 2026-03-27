# Maven Java 构建环境

## 定位

用于 Java / Maven 项目构建，并同时提供 Node.js 20 以支持前后端混合流水线。

## 镜像信息

| 项目 | 值 |
| --- | --- |
| 基础镜像 | `bellsoft/liberica-openjdk-debian:17` |
| 默认用户 | `appuser` |
| 工作目录 | `/workspace` |
| 默认命令 | `/bin/bash` |
| 关键工具 | `java`, `mvn`, `node`, `npm` |

## 构建

```bash
docker buildx build -t gitea-runtime-maven:latest ./runtime-maven
./scripts/runtimectl.sh build --only maven
```

## 最小验证

```bash
./scripts/runtimectl.sh test --only maven
```

## 常用用法

```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-maven:latest mvn clean package

docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-maven:latest mvn test
```

自定义 `settings.xml`：

```bash
docker run --rm \
  -v "$(pwd):/workspace" \
  -v "$(pwd)/settings.xml:/home/appuser/.m2/settings.xml" \
  -w /workspace \
  gitea-runtime-maven:latest mvn clean package
```

## 在 Gitea Actions 中使用

```yaml
jobs:
  java-build:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-maven:latest
    steps:
      - uses: actions/checkout@v4
      - run: mvn clean package
```

## 预装工具与环境

- 环境变量：`LANG`、`LANGUAGE`、`LC_ALL`、`TZ`、`PATH`
- 运行工具：`java`、`mvn`、`node`、`npm`
- Maven 版本：`3.9.12`
- 本地仓库：`/home/appuser/.m2`

## 安全与维护

- 以非 root 用户 `appuser` 运行
- Maven 发行包使用固定版本与 SHA512 校验
- Node.js 通过显式 NodeSource keyring 仓库安装
- Dockerfile 风格维护遵循 [docs/DOCKERFILE_STYLE.md](../docs/DOCKERFILE_STYLE.md)

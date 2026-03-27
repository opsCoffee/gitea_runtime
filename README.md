# Gitea Runtime

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](./VERSION)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](./.github/workflows/build.yml)

本项目提供了一系列用于构建 Gitea Runner 的 Docker 镜像的 Dockerfile 集合。通过自定义打包 Docker 镜像，可以预先完成运行环境的构建，从而显著减少 Gitea Runner 的执行时间。

## 🚀 快速开始

### 前置要求
- Docker 20.10+
- Docker Buildx（多架构构建）
- Git

### 5分钟快速体验

1. **克隆项目**
   ```bash
   git clone https://github.com/your-org/gitea-runtime.git
   cd gitea-runtime
   ```

2. **构建单个镜像**
   ```bash
   # 构建 Markdown 运行时
   ./scripts/runtimectl.sh build --only markdown
   
   # 测试镜像
   ./scripts/runtimectl.sh test --only markdown
   ```

3. **立即使用**
   ```bash
   # 检查 Markdown 文件
   docker run --rm -v $(pwd):/app gitea-runtime-markdown:latest \
     markdownlint-cli2 /app/README.md
   ```

### 完整构建流程

```bash
# 构建所有受支持的镜像
./scripts/runtimectl.sh build

# 仅预览将要执行的构建命令
./scripts/runtimectl.sh build --dry-run

# 运行完整测试套件
./scripts/runtimectl.sh pipeline --quick

# 仅针对多个指定 runtime 运行流水线
./scripts/runtimectl.sh pipeline --only markdown,maven --quick

# 查看构建结果
docker images | grep gitea-runtime
```

## 📋 项目说明

由于这些镜像将作为 Gitea Runner 的运行时环境，需确保与 `actions/checkout@v4` 等常用 Actions 的兼容性。因此，所有镜像均基于 Node.js 相关镜像构建，并在不影响功能的前提下，尽可能压缩了镜像体积。

### 🏗️ 架构概览

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   开发者推送     │───▶│   CI/CD 构建    │───▶│   镜像仓库      │
│                │    │                │    │                │
│ • Git Push     │    │ • 自动构建      │    │ • 版本管理      │
│ • Pull Request │    │ • 安全扫描      │    │ • 多架构支持    │
│ • 定时更新      │    │ • 性能测试      │    │ • 标签管理      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Gitea Runner   │
                       │                │
                       │ • 快速启动      │
                       │ • 预配置环境    │
                       │ • 标准化工具    │
                       └─────────────────┘
```

> 📖 详细架构文档请参考 [ARCHITECTURE.md](./ARCHITECTURE.md)

## 可用运行时环境

本项目当前支持以下运行时环境：

| 运行时名称 | 描述 | 基础镜像 | 主要工具 |
|------------|------|----------|----------|
| [runtime-markdown](./runtime-markdown/) | Markdown 格式化运行时 | node:lts-alpine3.20 | markdownlint-cli2 |
| [runtime-asustor](./runtime-asustor/) | ASUSTOR 应用运行时 | alpine:3.20 | python3, nodejs, npm |
| [runtime-template](./runtime-template/) | 安全模板处理运行时 | node:22-alpine | nuclei, generate-checksum |
| [runtime-latex](./runtime-latex/) | LaTeX 文档处理运行时 | node:20-bookworm-slim | TinyTeX, xelatex |
| [runtime-base](./runtime-base/) | 基础 Node.js 运行时 | node:22-alpine | node, npm, git |
| [runtime-maven](./runtime-maven/) | Maven Java 构建环境 | bellsoft/liberica-openjdk-debian:17 | java, mvn, node |
| [runtime-claudecode](./runtime-claudecode/) | Claude Code 开发环境 | node:22-alpine | claude, git, MCP 工具链 |

> `runtime-maven` 当前默认固定 Maven 3.9.12，并在构建时执行 SHA512 校验，以提升镜像构建可重现性。

## 快速开始

### 统一入口

仓库的脚本入口已经统一到 `./scripts/runtimectl.sh`，可用子命令如下：

```bash
./scripts/runtimectl.sh help
./scripts/runtimectl.sh build --help
./scripts/runtimectl.sh test --help
./scripts/runtimectl.sh pipeline --help
```

内部结构分为三层：
- `scripts/runtimectl.sh`: 单一主入口
- `scripts/commands/*`: 各命令实现
- `scripts/lib/*`: 公共库

### 构建镜像

```bash
./scripts/runtimectl.sh build
./scripts/runtimectl.sh build --only markdown
./scripts/runtimectl.sh build --only markdown,maven
./scripts/runtimectl.sh build --only base,claudecode --dry-run
./scripts/runtimectl.sh build --only markdown --dry-run --platforms linux/amd64
```

### 测试镜像

```bash
./scripts/runtimectl.sh test --only markdown
./scripts/runtimectl.sh test --only markdown,maven --dry-run
./scripts/runtimectl.sh test --only markdown --tag v20260327
./scripts/runtimectl.sh test --only markdown --image-name demo/image --tag test
```

`test` 子命令会按 runtime 执行最小真实工具测试，例如：
- `markdown` → 挂载临时 Markdown 文件并执行 `markdownlint-cli2 sample.md`
- `latex` → 挂载最小 tex 文件并执行 `xelatex -interaction=nonstopmode -halt-on-error document.tex`
- `template` → 挂载最小模板并执行 `nuclei -validate -t templates`
- `asustor` → 挂载最小 `script.py` 并执行 `python3 script.py`
- `base` → 挂载最小 `index.js` 并执行 `node index.js`
- `maven` → 挂载最小 `pom.xml` 并执行 `mvn -q -DskipTests help:evaluate -Dexpression=project.artifactId -DforceStdout`
- `claudecode` → 挂载最小 Git 仓库目录并执行 `install-claude-git-hook /workspace`

其中 `runtime-claudecode` 不再在镜像构建阶段假设存在宿主仓库工作区；若需要安装 Git hook，请在容器运行时执行 `install-claude-git-hook <repo-path>`。

### 性能监控

```bash
./scripts/runtimectl.sh performance --only markdown,maven --dry-run
./scripts/runtimectl.sh performance --analyze-only --report-dir /tmp/perf-reports
```

### 安全扫描

```bash
./scripts/runtimectl.sh security --only markdown
./scripts/runtimectl.sh security --baseline --report-dir /tmp/sec-reports
./scripts/runtimectl.sh security --only markdown --dry-run
```

`security` 与 `performance` 子命令都已统一支持 `--only`、`--report-dir`、基础参数校验和 dry-run 路径，便于本地验证和 CI smoke test。

### 自动优化

```bash
./scripts/runtimectl.sh optimize --dry-run
./scripts/runtimectl.sh optimize --backup
./scripts/runtimectl.sh optimize --aggressive
```

### 流水线执行

```bash
./scripts/runtimectl.sh pipeline --quick
./scripts/runtimectl.sh pipeline --only markdown,maven --quick
./scripts/runtimectl.sh pipeline --skip-build --skip-security --skip-performance --skip-optimization
./scripts/runtimectl.sh pipeline --only markdown --quick --dry-run
```

### 版本管理

```bash
./scripts/runtimectl.sh version current
./scripts/runtimectl.sh version bump patch --dry-run
./scripts/runtimectl.sh version release minor --message "Release vX.Y.Z" --allow-dirty
```

### 验证脚本入口

```bash
bash ./tests/smoke/runtimectl_smoke.sh
```

> 当前脚本默认共享同一组配置常量，统一定义在 `scripts/lib/config.sh`，用于收敛默认 registry、默认 tag、默认平台和支持的 runtime 列表。
>
> CI workflow 会通过 `scripts/ci/verify_workflow_config.sh` 校验 registry / namespace / runtime 列表与统一入口调用是否一致，通过 `tests/smoke/runtimectl_smoke.sh` 执行 CLI smoke test，并通过 `scripts/ci/verify_dockerfile_safety.sh` 阻止高风险 Dockerfile 写法（如 `curl|sh`、`wget|bash`、构建期 `GITHUB_WORKSPACE` 依赖）回流。
>
> 另外，当前仓库已移除 `runtime-markdown`、`runtime-maven`、`runtime-latex` 中的远程脚本管道执行写法，降低镜像构建阶段的供应链风险。
>
> 其中 `runtime-maven` 已固定 Maven 3.9.12 并执行 SHA512 校验；`runtime-latex` 现支持通过 `TINYTEX_INSTALLER_SHA256` 对 TinyTeX 安装脚本启用完整性校验。

## 镜像使用示例

### Markdown 格式化

```bash
docker run --rm -v $(pwd):/app gitea-runtime-markdown:latest markdownlint-cli2 /app/README.md
```

### ASUSTOR 应用开发

```bash
docker run --rm -v $(pwd):/app gitea-runtime-asustor:latest python3 /app/script.py
```

### 安全模板验证

```bash
docker run --rm -v $(pwd):/app gitea-runtime-template:latest nuclei -t /app/templates -u https://example.com
```

### LaTeX 文档编译

```bash
docker run --rm -v $(pwd):/app gitea-runtime-latex:latest xelatex /app/document.tex
```

## 在 Gitea Actions 中使用

示例 workflow 文件：

```yaml
name: Document Processing

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  markdown-lint:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-markdown:latest
    
    steps:
      - uses: actions/checkout@v4
      - name: Lint Markdown files
        run: markdownlint-cli2 "**/*.md"
  
  build-latex:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-latex:latest
    
    steps:
      - uses: actions/checkout@v4
      - name: Build LaTeX document
        run: xelatex document.tex
```

## 项目结构

```
gitea-runtime/
├── .dockerignore           # Docker 构建忽略文件
├── README.md               # 项目主文档
├── OPTIMIZATION.md         # 优化记录
├── scripts/
│   ├── runtimectl.sh       # 单一脚本入口
│   ├── commands/           # build / test / security / performance / optimize / pipeline / version
│   ├── lib/                # 公共库
│   └── ci/                 # CI 辅助脚本
├── tests/
│   └── smoke/              # CLI smoke test
├── runtime-markdown/       # Markdown 格式化运行时
│   ├── Dockerfile
│   └── README.md
├── runtime-asustor/        # ASUSTOR 应用运行时
│   ├── Dockerfile
│   └── README.md
├── runtime-template/       # 安全模板处理运行时
│   ├── Dockerfile
│   └── README.md
├── runtime-latex/          # LaTeX 文档处理运行时
│   ├── Dockerfile
│   └── README.md
├── runtime-base/           # 基础 Node.js 运行时
│   ├── Dockerfile
│   └── README.md
├── runtime-maven/          # Maven Java 构建环境
│   ├── Dockerfile
│   └── README.md
└── runtime-claudecode/     # Claude Code 开发环境
    ├── Dockerfile
    └── README.md
```

## 贡献指南

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交您的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开一个 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

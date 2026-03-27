# Gitea Runtime

本项目维护一组面向 Gitea Runner 的运行时镜像。目标是把常用工具链预装进镜像，减少流水线冷启动时间，并把构建、测试与发布入口统一到同一套脚本体系。

## 文档导航

- [docs/README.md](docs/README.md)：文档索引
- [ARCHITECTURE.md](ARCHITECTURE.md)：结构与自动化链路
- [docs/DOCKERFILE_STYLE.md](docs/DOCKERFILE_STYLE.md)：Dockerfile 风格规范
- [OPTIMIZATION.md](OPTIMIZATION.md)：历史优化记录

## 运行时矩阵

| runtime | 说明 | 基础镜像 | 关键工具 | 文档 |
| --- | --- | --- | --- | --- |
| `markdown` | Markdown 检查与格式验证 | `node:lts-alpine3.20` | `markdownlint-cli2` | [runtime-markdown/README.md](runtime-markdown/README.md) |
| `asustor` | ASUSTOR/NAS 相关脚本运行（须以 root 运行，否则 workflow 会因权限中断） | `alpine:3.20` | `python3`, `nodejs`, `npm` | [runtime-asustor/README.md](runtime-asustor/README.md) |
| `template` | 安全模板处理与验证 | `node:22-alpine` | `nuclei`, `generate-checksum` | [runtime-template/README.md](runtime-template/README.md) |
| `latex` | LaTeX 编译与中文文档处理 | `node:20.17.0-bookworm-slim` | `TinyTeX`, `xelatex` | [runtime-latex/README.md](runtime-latex/README.md) |
| `base` | 基础 Node.js 运行环境 | `node:22.6.0-alpine` | `node`, `npm`, `git` | [runtime-base/README.md](runtime-base/README.md) |
| `maven` | Java / Maven 构建环境 | `bellsoft/liberica-openjdk-debian:17` | `java`, `mvn`, `nodejs` | [runtime-maven/README.md](runtime-maven/README.md) |
| `claudecode` | Claude Code 开发环境 | `node:22.6.0-alpine` | `claude`, `git`, MCP 工具链 | [runtime-claudecode/README.md](runtime-claudecode/README.md) |

## 统一脚本入口

项目脚本统一通过 [scripts/runtimectl.sh](scripts/runtimectl.sh) 调用：

```bash
./scripts/runtimectl.sh help
./scripts/runtimectl.sh build --help
./scripts/runtimectl.sh test --help
./scripts/runtimectl.sh pipeline --help
```

命令实现位于：
- [scripts/commands](scripts/commands)
- [scripts/lib](scripts/lib)
- [scripts/ci](scripts/ci)

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Buildx
- Git

### 构建

```bash
# 构建全部 runtime
./scripts/runtimectl.sh build

# 构建单个 runtime
./scripts/runtimectl.sh build --only markdown

# 构建多个 runtime
./scripts/runtimectl.sh build --only markdown,maven

# 仅预览命令
./scripts/runtimectl.sh build --only base,claudecode --dry-run
```

### 测试

```bash
# 执行最小功能测试
./scripts/runtimectl.sh test --only markdown

# 同时测试多个 runtime
./scripts/runtimectl.sh test --only markdown,maven --dry-run

# 测试指定标签
./scripts/runtimectl.sh test --only latex --tag v20260328
```

### 其他命令

```bash
./scripts/runtimectl.sh security --only base --dry-run
./scripts/runtimectl.sh performance --only base --analyze-only --report-dir /tmp/perf
./scripts/runtimectl.sh optimize --only markdown --dry-run
./scripts/runtimectl.sh pipeline --only markdown,template --quick
./scripts/runtimectl.sh version current
```

## 本地验证

最小脚本回归：

```bash
bash ./tests/smoke/runtimectl_smoke.sh
```

常用静态校验：

```bash
bash -n scripts/runtimectl.sh scripts/commands/*.sh scripts/lib/*.sh scripts/ci/*.sh tests/smoke/runtimectl_smoke.sh
shellcheck -x scripts/runtimectl.sh scripts/commands/*.sh scripts/lib/*.sh scripts/ci/*.sh tests/smoke/runtimectl_smoke.sh
./scripts/ci/verify_workflow_config.sh
./scripts/ci/verify_dockerfile_safety.sh
```

说明：
- `performance` 命令依赖宿主提供 `numfmt`
- 非 `--analyze-only` 的 `performance` 路径还依赖 `bc`
- `security` 命令在本地没有扫描器时，会尝试通过 Docker 拉取 Trivy 镜像

## 文档组织原则

当前文档按以下边界组织：
- 根 README：项目入口、运行时矩阵、统一命令和导航
- runtime README：单个镜像的定位、构建、验证与使用
- 架构文档：整体结构与自动化链路
- 规范文档：Dockerfile 风格和后续维护规则

不要再把同一类信息同时散落在根 README、运行时 README 和零散说明里。

## 项目结构

```text
gitea-runtime/
├── README.md
├── ARCHITECTURE.md
├── OPTIMIZATION.md
├── docs/
│   ├── README.md
│   └── DOCKERFILE_STYLE.md
├── scripts/
│   ├── runtimectl.sh
│   ├── commands/
│   ├── lib/
│   └── ci/
├── tests/
│   └── smoke/
├── runtime-markdown/
├── runtime-asustor/
├── runtime-template/
├── runtime-latex/
├── runtime-base/
├── runtime-maven/
└── runtime-claudecode/
```

## 贡献约束

- 新增或修改镜像时，先遵循 [docs/DOCKERFILE_STYLE.md](docs/DOCKERFILE_STYLE.md)
- 新增命令时，优先放入 `scripts/commands/`，不要再恢复根目录多入口脚本
- 更新文档时，优先维护导航和模板一致性，不要为单个 runtime 再发明一套章节结构

## 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE)。

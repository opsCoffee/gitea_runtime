# Gitea Runtime

本项目提供了一系列用于构建 Gitea Runner 的 Docker 镜像的 Dockerfile 集合。通过自定义打包 Docker 镜像，可以预先完成运行环境的构建，从而显著减少 Gitea Runner 的执行时间。

## 项目说明

由于这些镜像将作为 Gitea Runner 的运行时环境，需确保与 `actions/checkout@v4` 等常用 Actions 的兼容性。因此，所有镜像均基于 Node.js 相关镜像构建，并在不影响功能的前提下，尽可能压缩了镜像体积。

## 可用运行时环境

本项目提供以下运行时环境：

| 运行时名称 | 描述 | 基础镜像 | 主要工具 |
|------------|------|----------|----------|
| [runtime-markdown](./runtime-markdown/) | Markdown 格式化运行时 | node:lts-alpine3.20 | markdownlint-cli2 |
| [runtime-asustor](./runtime-asustor/) | ASUSTOR 应用运行时 | alpine:3.20 | python3, nodejs, npm |
| [runtime-template](./runtime-template/) | 安全模板处理运行时 | node:22-alpine | nuclei, templates-stats |
| [runtime-latex](./runtime-latex/) | LaTeX 文档处理运行时 | node:20-bookworm-slim | TinyTeX, xelatex |

## 快速开始

### 构建所有镜像

```bash
./build.sh
```

### 构建特定镜像

```bash
./build.sh --only markdown  # 构建 Markdown 运行时
./build.sh --only asustor   # 构建 ASUSTOR 运行时
./build.sh --only template  # 构建模板处理运行时
./build.sh --only latex     # 构建 LaTeX 运行时
```

### 测试镜像

```bash
./test_images.sh                    # 测试所有镜像
./test_images.sh markdown          # 测试特定镜像
./test_images.sh --date-tag latex  # 使用日期标签测试
```

### 性能监控

```bash
./performance_monitor.sh            # 完整性能分析
./performance_monitor.sh --analyze-only  # 仅分析现有镜像
```

### 安全扫描

```bash
./security_scanner.sh               # 全面安全扫描
./security_scanner.sh --only markdown  # 扫描特定镜像
./security_scanner.sh --baseline   # 生成安全基线
```

### 自动优化

```bash
./auto_optimizer.sh --dry-run       # 预览优化建议
./auto_optimizer.sh --backup        # 优化前创建备份
./auto_optimizer.sh --aggressive    # 激进优化模式
```

### 构建选项

```bash
./build.sh --help  # 显示所有可用选项
```

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
├── build.sh                # 构建脚本
├── test_images.sh          # 测试脚本
├── .dockerignore           # Docker 构建忽略文件
├── README.md               # 项目主文档
├── OPTIMIZATION.md         # 优化记录
├── runtime-markdown/       # Markdown 格式化运行时
│   ├── Dockerfile
│   └── README.md
├── runtime-asustor/        # ASUSTOR 应用运行时
│   ├── Dockerfile
│   └── README.md
├── runtime-template/       # 安全模板处理运行时
│   ├── Dockerfile
│   └── README.md
└── runtime-latex/          # LaTeX 文档处理运行时
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
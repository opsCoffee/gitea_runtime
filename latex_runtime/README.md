# README

## 项目概述
本项目提供了一个 Docker 镜像，集成了 TinyTeX 和 Node.js 环境，适用于需要同时使用 LaTeX 和 Node.js 的项目。镜像通过多阶段构建，确保最终镜像尽可能小。

## 构建镜像
要构建此 Docker 镜像，请确保已安装 Docker，然后在包含 `Dockerfile` 的目录中运行以下命令：

```bash
docker build -t tinytex-node .
```

## 运行容器
构建完成后，您可以通过以下命令运行容器：

```bash
docker run -it --rm tinytex-node
```

默认情况下，容器会显示 `tlmgr` 的帮助信息。您可以通过覆盖默认命令来执行其他操作，例如：

```bash
docker run -it --rm tinytex-node tlmgr --version
```

## 使用说明
1. **TinyTeX**：TinyTeX 是一个轻量级的 LaTeX 发行版，已预装了一些常用的 LaTeX 包（如 `enumitem`、`titlesec`、`fontawesome5`、`parskip`、`ctex`、`noto` 和 `fandol`）。您可以通过 `tlmgr` 命令管理 TeX 包。
2. **Node.js**：镜像中包含了 Node.js 的 LTS 版本，您可以在容器内运行 Node.js 应用程序。
3. **工作目录**：容器的工作目录设置为 `/workdir`，您可以通过挂载卷的方式将本地目录映射到容器内：

   ```bash
   docker run -it --rm -v $(pwd):/workdir tinytex-node
   ```

## 环境变量
- `PATH`：已设置为包含 TinyTeX 和 Node.js 的可执行文件路径。

## 示例
以下是一个简单的示例，展示如何在容器内编译 LaTeX 文档：

1. 创建一个简单的 LaTeX 文件 `example.tex`：

   ```latex
   \documentclass{article}
   \begin{document}
   Hello, World!
   \end{document}
   ```

2. 使用以下命令编译 `example.tex`：

   ```bash
   docker run -it --rm -v $(pwd):/workdir tinytex-node pdflatex example.tex
   ```

编译完成后，您将在当前目录下找到生成的 `example.pdf` 文件。

## 优点
1. **多阶段构建**：使用多阶段构建有效减小了最终镜像的大小，避免了不必要的依赖和文件。
2. **依赖管理**：在每个阶段都进行了依赖清理，减少了镜像的层大小，确保镜像更轻量化。
3. **环境变量设置**：正确设置了 `PATH` 环境变量，确保 `tlmgr` 和其他工具可以在容器内正常使用。
4. **工作目录设置**：设置了 `WORKDIR`，方便用户在容器内进行操作，提升使用体验。

## 注意事项
- 镜像中已清理了不必要的依赖和临时文件，以确保镜像尽可能小。
- 如果需要安装额外的 TeX 包，可以使用 `tlmgr install <package>` 命令。

## 维护
如有任何问题或建议，请提交 issue 或 pull request。我们将尽快处理。

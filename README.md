# Gitea Runtime

本项目提供了一系列用于构建 Gitea Runner 的 Docker 镜像的 Dockerfile 集合。通过自定义打包 Docker 镜像，可以预先完成运行环境的构建，从而显著减少 Gitea Runner 的执行时间。

## 项目说明

由于这些镜像将作为 Gitea Runner 的运行时环境，需确保与 `actions/checkout@v4` 等常用 Actions 的兼容性。因此，所有镜像均基于 Node.js 相关镜像构建，并在不影响功能的前提下，尽可能压缩了镜像体积。

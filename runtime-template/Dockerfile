# =================================================================
# Gitea Runtime: 安全模板处理运行时
# =================================================================

# =================================================================
# 第一阶段：构建阶段
# =================================================================
FROM golang:1.22-alpine AS builder

# 安装依赖
RUN apk add --no-cache git

# 设置工作目录
WORKDIR /app

# 一次性安装所有 Go 工具，减少层数
RUN go install -v github.com/projectdiscovery/templates-stats@latest && \
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest && \ 
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/generate-checksum@latest && \
    rm -rf /app

# =================================================================
# 第二阶段：运行时阶段
# =================================================================
FROM node:22-alpine

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.description="A template processing environment with Nuclei and Node.js" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT"

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# 复制编译好的二进制文件到新镜像
COPY --from=builder /go/bin/nuclei /go/bin/generate-checksum /go/bin/templates-stats /usr/local/bin/

# 安装运行时所需的依赖并清理缓存
RUN apk add --no-cache dos2unix curl vim bash git python3 py3-pip tree && \
    mkdir -p ~/.config/nuclei/ && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# 创建非 root 用户
RUN adduser -D appuser && \
    mkdir -p /app && \
    chown -R appuser:appuser /app && \
    mkdir -p /home/appuser/.config/nuclei && \
    chown -R appuser:appuser /home/appuser/.config

# 设置工作目录
WORKDIR /app

# 切换到非 root 用户
USER appuser

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD nuclei -version || exit 1

# 设置默认命令
CMD ["bash"]
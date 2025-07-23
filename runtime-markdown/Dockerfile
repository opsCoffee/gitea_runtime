# =================================================================
# Gitea Runtime: Markdown 格式化运行时
# =================================================================

# =================================================================
# 第一阶段：构建阶段
# =================================================================
FROM node:lts-alpine3.20 AS builder

# 设置环境变量
ENV LANG=en_US.utf8

# 安装必要的工具和全局 npm 包
RUN apk add --no-cache bash curl git python3 && \
    ln -sf python3 /usr/bin/python && \
    npm install -g markdownlint-cli2

# =================================================================
# 第二阶段：运行时阶段
# =================================================================
FROM node:lts-alpine3.20

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.description="A lightweight Markdown linting and formatting environment for Gitea Runner" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT"

# 设置环境变量
ENV LANG=en_US.utf8

# 安装运行时必要的工具，并清理缓存
RUN apk add --no-cache bash curl git python3 vim dos2unix perl && \
    ln -sf python3 /usr/bin/python && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# 从构建阶段复制已安装的 npm 包
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin/markdownlint-cli2 /usr/local/bin/

# 下载并执行远程脚本
RUN curl -sSL https://git.io/JcGER | /bin/ash && \
    rm -rf /tmp/* /var/tmp/*

# 创建非 root 用户
RUN adduser -D appuser && \
    mkdir -p /app && \
    chown -R appuser:appuser /app

# 设置工作目录
WORKDIR /app

# 切换到非 root 用户
USER appuser

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD markdownlint-cli2 --version || exit 1

# 设置默认命令
CMD ["bash"]
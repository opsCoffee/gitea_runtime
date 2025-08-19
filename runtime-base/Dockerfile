# 使用参数化的Node.js版本
ARG NODE_VERSION=22.6.0
FROM node:${NODE_VERSION}-alpine

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 安装必要工具并设置时区
RUN set -eux; \
    # 更新包索引并安装必要工具
    apk update && \
    apk add --no-cache \
        dos2unix \
        curl \
        vim \
        bash \
        git \
        openssh-client \
        rsync \
        tzdata && \
    # 设置时区
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    # 清理缓存
    rm -rf /var/cache/apk/* && \
    # 验证安装
    node --version && \
    npm --version

# 设置工作目录
WORKDIR /app

# 更改工作目录所有权
RUN chown -R nextjs:nodejs /app

# 切换到非root用户
USER nextjs

# 暴露常用端口（可根据需要调整）
EXPOSE 3000

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node --version || exit 1

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.title="Gitea Runtime Base" \
      org.opencontainers.image.description="Base Node.js ${NODE_VERSION} runtime environment for Gitea Actions with essential development tools" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.documentation="https://git.httpx.online/kenyon/gitea-runtime/src/branch/main/README.md" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://git.httpx.online/kenyon/gitea-runtime" \
      maintainer="kenyon <kenyon@noreply.localhost>"

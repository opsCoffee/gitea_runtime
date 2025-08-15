# =================================================================
# Gitea Runtime: 安全模板处理运行时
# =================================================================

# 构建参数
ARG NODE_VERSION=22.6.0
ARG NUCLEI_VERSION=v3.1.8
ARG GITEA_VERSION=dev
ARG BUILD_DATE

# =================================================================
# 第一阶段：构建阶段
# =================================================================
FROM golang:1.22-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache git ca-certificates

# 设置工作目录
WORKDIR /go/src

# 一次性安装所有 Go 工具，使用固定版本避免依赖问题
RUN go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@${NUCLEI_VERSION} && \
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/generate-checksum@${NUCLEI_VERSION} && \
    # 清理Go缓存和临时文件，减少层大小
    go clean -cache -modcache -testcache && \
    rm -rf /go/src /root/.cache /tmp/*

# =================================================================
# 第二阶段：运行时阶段
# =================================================================
FROM node:${NODE_VERSION}-alpine

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.title="Gitea Runtime Template" \
      org.opencontainers.image.description="Security template processing environment with Nuclei and Node.js ${NODE_VERSION}" \
      org.opencontainers.image.version="${GITEA_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.documentation="https://git.httpx.online/kenyon/gitea-runtime/src/branch/main/runtime-template/README.md" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://git.httpx.online/kenyon/gitea-runtime" \
      maintainer="kenyon <kenyon@noreply.localhost>"

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai

# 复制编译好的二进制文件到新镜像
COPY --from=builder /go/bin/nuclei /go/bin/generate-checksum /usr/local/bin/

# 创建非 root 用户（使用与项目一致的 UID/GID）
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001 -G nodejs

# 安装运行时所需的依赖并清理缓存
RUN set -eux; \
    apk update && \
    apk add --no-cache \
        dos2unix \
        curl \
        bash \
        git \
        python3 \
        py3-pip \
        tree \
        tzdata && \
    # 设置时区
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    # 创建必要目录并设置权限
    mkdir -p /app /home/appuser/.config/nuclei && \
    chown -R appuser:nodejs /app /home/appuser/.config && \
    # 清理缓存
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \
    # 验证安装
    node --version && \
    npm --version && \
    nuclei -version

# 设置工作目录
WORKDIR /app

# 切换到非 root 用户
USER appuser

# 添加健康检查 - 验证核心工具是否正常工作
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD nuclei -version && generate-checksum -version || exit 1

# 设置默认命令
CMD ["bash"]
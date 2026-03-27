# =================================================================
# Gitea Runtime: ASUSTOR 应用运行时
# =================================================================

FROM alpine:3.20

ARG GITEA_VERSION=dev
ARG BUILD_DATE

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.title="Gitea Runtime ASUSTOR" \
      org.opencontainers.image.description="A lightweight runtime environment for ASUSTOR applications" \
      org.opencontainers.image.version="${GITEA_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.documentation="https://git.httpx.online/kenyon/gitea-runtime/src/branch/main/runtime-asustor/README.md" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://git.httpx.online/kenyon/gitea-runtime"

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    PYTHONUNBUFFERED=1

# 安装必要的工具并清理缓存
RUN apk add --no-cache python3 nodejs npm git tzdata && \
    # 设置时区
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# 设置工作目录
WORKDIR /app

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python3 -c "import sys; sys.exit(0)" || exit 1

# 设置默认命令
CMD ["sh"]

FROM alpine:3.20

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.description="A lightweight runtime environment for ASUSTOR applications" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime"

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    PYTHONUNBUFFERED=1

# 安装必要的工具并清理缓存
RUN apk add --no-cache python3 nodejs npm git && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

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
  CMD python3 -c "import sys; sys.exit(0)" || exit 1

# 设置默认命令
CMD [ "sh" ]
# =================================================================
# Gitea Runtime: ASUSTOR 打包 + Gitea Action 极简运行时
# =================================================================

FROM alpine:3.20

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.description="A lightweight runtime environment for ASUSTOR applications" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT"

# 设置环境变量
ENV LANG=C.UTF-8 \
    TZ=Asia/Shanghai \
    PYTHONUNBUFFERED=1

# 安装必要的工具并清理缓存
RUN apk add --no-cache \
      python3 \
      nodejs \
      npm \
      git

# 设置工作目录
WORKDIR /app

# 健康检查（简单 Python 脚本验证）,只在 Action 内跑，不作为长时间运行的容器，省略，节省空间
# HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#   CMD python3 -c "import sys; sys.exit(0)" || exit 1

# 默认执行 shell
CMD ["sh"]

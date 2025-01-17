FROM node:lts-alpine

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    PYTHONUNBUFFERED=1

# 安装 Python 和 Git
RUN apk add --no-cache python3 git && \
    ln -sf python3 /usr/bin/python && \
    node -v && \
    npm -v && \
    python --version && \
    git --version
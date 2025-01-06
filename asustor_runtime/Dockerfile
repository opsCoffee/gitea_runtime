FROM node:22.6.0-alpine

# 安装必要的依赖并清理缓存
RUN apk add --update --no-cache python3 git && \
    ln -sf python3 /usr/bin/python && \
    rm -rf /var/cache/apk/*

# 设置环境变量
ENV LANG en_US.UTF-8
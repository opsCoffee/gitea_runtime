FROM node:lts-slim

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    PYTHONUNBUFFERED=1

# 安装必要的依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app
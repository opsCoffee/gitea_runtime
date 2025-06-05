FROM node:lts-alpine

# 设置环境变量
ENV LANG=en_US.utf8

# 安装必要的工具和全局 npm 包，下载并执行远程脚本，并清理缓存
RUN apk add --no-cache bash curl git python3 vim dos2unix perl && \
    ln -sf python3 /usr/bin/python && \
    npm install -g markdownlint-cli2 && \
    curl -sSL https://git.io/JcGER | /bin/ash && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# 设置默认命令
CMD ["bash"]
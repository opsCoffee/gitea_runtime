FROM node:22.6.0-alpine

RUN apk add --no-cache dos2unix curl vim bash git \
    && npm i -g markdownlint-cli2 \
    && curl -sSL https://git.io/JcGER | /bin/ash

ENV LANG en_US.utf8

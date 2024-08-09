# 第一阶段：构建
# 使用具体版本的官方基础镜像，确保一致性和可重现性
FROM golang:1.22-alpine AS builder

# 安装依赖
RUN apk add --no-cache git

# 设置工作目录
WORKDIR /app

# 克隆projectdiscovery/nuclei项目，一次性完成两个构建任务
RUN git clone https://github.com/projectdiscovery/nuclei.git --depth 1 \
    && cd nuclei/cmd/nuclei \
    && go build -o /nuclei \
    && cd ../generate-checksum \
    && go build -o /generate-checksum

# 克隆并构建projectdiscovery/templates-stats项目
RUN git clone https://github.com/projectdiscovery/templates-stats.git --depth 1 \
    && cd templates-stats \
    && go build -o /templates-stats

# 清理不必要的文件以减小镜像大小
RUN rm -rf /app

# 第二阶段：创建运行时镜像
FROM node:22.6.0-alpine

# 复制编译好的二进制文件到新镜像
COPY --from=builder /templates-stats /usr/local/bin/templates-stats
COPY --from=builder /nuclei /usr/local/bin/nuclei
COPY --from=builder /generate-checksum /usr/local/bin/generate-checksum

# 安装运行时所需的依赖
RUN apk add --no-cache dos2unix curl vim bash git python3 py3-pip tree \
    && mkdir -p ~/.config/nuclei/

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV LANG en_US.utf8


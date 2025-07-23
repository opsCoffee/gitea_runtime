# =================================================================
# 第一阶段：构建一个精简的 TinyTeX 环境
# =================================================================
FROM debian:12-slim AS tex-builder

ENV DEBIAN_FRONTEND=noninteractive

# Step 1: 安装系统级依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        perl \
        fontconfig \
        libfontconfig1-dev \
        libfreetype6-dev \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 将 PATH 设置放在构建逻辑的顶部
ENV PATH="/root/.TinyTeX/bin/x86_64-linux:$PATH"

# Step 2: 复制预先下载的安装文件
COPY assets/install-bin-unix.sh /tmp/
COPY assets/TinyTeX-1.tar.gz /tmp/

# Step 3: 执行本地安装脚本
RUN chmod +x /tmp/install-bin-unix.sh && \
    /tmp/install-bin-unix.sh /tmp/TinyTeX-1.tar.gz

# Step 4: 安装 LaTeX 扩展包并进行极限压缩
# 优化：移除庞大的字体集合，只安装明确需要的包
RUN tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet && \
    tlmgr option -- autobackup 0 && \
    tlmgr install \
        enumitem \
        titlesec \
        fontawesome5 \
        parskip \
        ctex \
        fandol && \
    # 清理不必要的文档、源文件和备份，大幅减小体积
    rm -rf /root/.TinyTeX/texmf-dist/doc \
           /root/.TinyTeX/texmf-dist/source \
           /root/.TinyTeX/tlpkg/backups \
           /root/.TinyTeX/tlpkg/temp \
           /root/.TinyTeX/install-tl.log \
           /tmp/install-bin-unix.sh \
           /tmp/TinyTeX-1.tar.gz && \
    # 移除 tlmgr 的路径缓存，进一步减小体积
    tlmgr path remove


# =================================================================
# 第二阶段：构建最终的 Node.js + TeX 运行时镜像
# =================================================================
FROM node:20-bookworm-slim

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="Your Name <your.email@example.com>" \
      org.opencontainers.image.description="A lean runtime image with Node.js 20 and a compressed TinyTeX environment."

ENV DEBIAN_FRONTEND=noninteractive

# 安装 TeX 运行所需的动态链接库
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        perl libfontconfig1 libfreetype6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 将精简后的 TinyTeX 复制到最终镜像
COPY --from=tex-builder /root/.TinyTeX /usr/local/TinyTeX

# 设置环境变量，让系统能找到 TeX 程序
ENV PATH="/usr/local/TinyTeX/bin/x86_64-linux:$PATH"
WORKDIR /workdir

# 修正：仅修改工作目录的所有权，遵循最小权限原则
RUN chown -R node:node /workdir

# 切换到非 root 用户，增强安全性
USER node

# 默认命令，检查 xelatex 是否安装成功
CMD ["xelatex", "--version"]
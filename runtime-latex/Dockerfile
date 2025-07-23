# =================================================================
# Gitea Runtime: LaTeX 文档处理运行时
# =================================================================

# =================================================================
# 第一阶段：构建精简的 TinyTeX 环境
# =================================================================
FROM debian:12-slim AS tex-builder

ENV DEBIAN_FRONTEND=noninteractive
# 将 PATH 设置在顶部，确保后续所有 RUN 指令都能使用
ENV PATH="/root/.TinyTeX/bin/x86_64-linux:$PATH"

# 安装系统级依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        perl \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 确保临时目录有正确的权限
RUN mkdir -p /tmp && chmod 777 /tmp

# 在线安装 TinyTeX、LaTeX 扩展包并进行极限压缩
RUN wget -q -O /tmp/install-tinytex.sh https://yihui.org/tinytex/install-bin-unix.sh && \
    # 创建安装目录并确保权限
    mkdir -p /root/.TinyTeX && chmod 755 /root/.TinyTeX && \
    # 执行安装脚本，它会自动下载 TinyTeX
    sh /tmp/install-tinytex.sh && \
    # 安装完成后立即删除安装脚本
    rm /tmp/install-tinytex.sh && \
    # 设置清华大学的 CTAN 镜像源并安装所需宏包
    tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet && \
    tlmgr option -- autobackup 0 && \
    tlmgr install \
        enumitem \
        titlesec \
        fontawesome5 \
        parskip \
        ctex \
        fandol && \
    # 极限清理，移除所有不必要的文档、源文件和缓存
    rm -rf /root/.TinyTeX/texmf-dist/doc \
           /root/.TinyTeX/texmf-dist/source \
           /root/.TinyTeX/tlpkg/backups \
           /root/.TinyTeX/tlpkg/temp \
           /root/.TinyTeX/install-tl.log && \
    # 移除 tlmgr 的路径缓存，进一步减小体积
    tlmgr path remove

# =================================================================
# 第二阶段：构建最终的 Node.js + TeX 运行时镜像
# =================================================================
FROM node:20-bookworm-slim

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.description="A lean runtime image with Node.js 20 and a compressed TinyTeX environment" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT"

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

# 创建工作目录
WORKDIR /app

# 修改工作目录的所有权，遵循最小权限原则
RUN chown -R node:node /app

# 切换到非 root 用户，增强安全性
USER node

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD xelatex --version || exit 1

# 设置默认命令
CMD ["xelatex", "--version"]
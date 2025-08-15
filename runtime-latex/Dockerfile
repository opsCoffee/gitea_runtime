# =================================================================
# Gitea Runtime: LaTeX 文档处理运行时
# =================================================================

# 构建参数
ARG NODE_VERSION=20.17.0
ARG TINYTEX_VERSION=2024.01
ARG GITEA_VERSION=dev
ARG BUILD_DATE
ARG TARGETARCH

# =================================================================
# 第一阶段：构建精简的 TinyTeX 环境
# =================================================================
FROM debian:12-slim AS tex-builder

# 重新声明构建参数（多阶段构建需要）
ARG TINYTEX_VERSION=2024.01
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

# 根据目标架构设置 TinyTeX 二进制路径
RUN case "${TARGETARCH}" in \
        amd64) TINYTEX_ARCH="x86_64-linux" ;; \
        arm64) TINYTEX_ARCH="aarch64-linux" ;; \
        arm) TINYTEX_ARCH="armhf-linux" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    echo "TINYTEX_ARCH=${TINYTEX_ARCH}" > /tmp/arch.env

# 安装系统级依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        perl \
        ca-certificates \
        gnupg2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 确保临时目录有正确的权限
RUN mkdir -p /tmp && chmod 777 /tmp

# 在线安装 TinyTeX、LaTeX 扩展包并进行极限压缩
RUN set -e && \
    . /tmp/arch.env && \
    # 下载并验证 TinyTeX 安装脚本
    echo "Downloading TinyTeX installation script..." && \
    wget -q -O /tmp/install-tinytex.sh https://yihui.org/tinytex/install-bin-unix.sh && \
    # 创建安装目录并确保权限
    mkdir -p /root/.TinyTeX && chmod 755 /root/.TinyTeX && \
    # 执行安装脚本，它会自动下载 TinyTeX
    echo "Installing TinyTeX for architecture: ${TINYTEX_ARCH}" && \
    sh /tmp/install-tinytex.sh && \
    # 安装完成后立即删除安装脚本
    rm /tmp/install-tinytex.sh && \
    # 设置 PATH 环境变量
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    # 验证 TinyTeX 安装
    echo "Verifying TinyTeX installation..." && \
    tlmgr --version && \
    # 配置 tlmgr（只使用支持的选项）
    echo "Configuring tlmgr..." && \
    tlmgr option -- autobackup 0 && \
    # 显示当前配置以便调试
    tlmgr option && \
    # 分批安装包，避免依赖冲突
    echo "Installing LaTeX packages..." && \
    tlmgr install enumitem titlesec fontawesome5 parskip && \
    # 单独安装中文支持包
    echo "Installing Chinese support packages..." && \
    tlmgr install ctex fandol && \
    # 更新格式文件
    echo "Updating format files..." && \
    fmtutil-sys --all && \
    # 极限清理，移除所有不必要的文档、源文件和缓存
    echo "Performing cleanup to reduce image size..." && \
    rm -rf /root/.TinyTeX/texmf-dist/doc \
           /root/.TinyTeX/texmf-dist/source \
           /root/.TinyTeX/tlpkg/backups \
           /root/.TinyTeX/tlpkg/temp \
           /root/.TinyTeX/install-tl.log \
           /tmp/* && \
    # 移除 tlmgr 的路径缓存，进一步减小体积
    tlmgr path remove && \
    echo "TinyTeX installation and optimization completed successfully."

# =================================================================
# 第二阶段：构建最终的 Node.js + TeX 运行时镜像
# =================================================================
FROM node:${NODE_VERSION}-bookworm-slim

# 重新声明运行时需要的构建参数
ARG NODE_VERSION=20.17.0
ARG TINYTEX_VERSION=2024.01
ARG GITEA_VERSION=dev
ARG BUILD_DATE
ARG TARGETARCH

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.title="Gitea Runtime LaTeX" \
      org.opencontainers.image.description="LaTeX document processing environment with Node.js ${NODE_VERSION} and TinyTeX ${TINYTEX_VERSION}" \
      org.opencontainers.image.version="${GITEA_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.documentation="https://git.httpx.online/kenyon/gitea-runtime/src/branch/main/runtime-latex/README.md" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://git.httpx.online/kenyon/gitea-runtime" \
      maintainer="kenyon <kenyon@noreply.localhost>"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Shanghai

# 根据目标架构设置 TinyTeX 二进制路径
RUN case "${TARGETARCH}" in \
        amd64) TINYTEX_ARCH="x86_64-linux" ;; \
        arm64) TINYTEX_ARCH="aarch64-linux" ;; \
        arm) TINYTEX_ARCH="armhf-linux" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    echo "export PATH=\"/usr/local/TinyTeX/bin/${TINYTEX_ARCH}:\$PATH\"" > /etc/profile.d/tinytex.sh && \
    chmod +x /etc/profile.d/tinytex.sh

# 安装 TeX 运行所需的动态链接库和系统工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        perl \
        libfontconfig1 \
        libfreetype6 \
        fontconfig \
        fonts-liberation \
        tzdata \
        curl \
        bash && \
    # 设置时区
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    # 清理缓存
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 创建非 root 用户（使用与项目一致的 UID/GID）
RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs appuser

# 将精简后的 TinyTeX 复制到最终镜像
COPY --from=tex-builder /root/.TinyTeX /usr/local/TinyTeX

# 设置 TinyTeX 权限并创建必要目录
RUN chown -R appuser:nodejs /usr/local/TinyTeX && \
    mkdir -p /app /home/appuser && \
    chown -R appuser:nodejs /app /home/appuser

# 设置环境变量，让系统能找到 TeX 程序
RUN case "${TARGETARCH}" in \
        amd64) TINYTEX_ARCH="x86_64-linux" ;; \
        arm64) TINYTEX_ARCH="aarch64-linux" ;; \
        arm) TINYTEX_ARCH="armhf-linux" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    echo "PATH=/usr/local/TinyTeX/bin/${TINYTEX_ARCH}:\$PATH" >> /etc/environment

ENV PATH="/usr/local/TinyTeX/bin/x86_64-linux:/usr/local/TinyTeX/bin/aarch64-linux:/usr/local/TinyTeX/bin/armhf-linux:$PATH"

# 创建工作目录
WORKDIR /app

# 切换到非 root 用户，增强安全性
USER appuser

# 创建简单的 LaTeX 测试文件用于健康检查
RUN echo '\documentclass{article}\begin{document}Hello LaTeX!\end{document}' > /tmp/test.tex

# 添加健康检查 - 测试实际的 LaTeX 编译功能
HEALTHCHECK --interval=30s --timeout=15s --start-period=10s --retries=3 \
  CMD xelatex --version && \
      echo '\documentclass{article}\begin{document}Health Check\end{document}' > /tmp/health.tex && \
      xelatex -interaction=nonstopmode -output-directory=/tmp /tmp/health.tex >/dev/null 2>&1 && \
      test -f /tmp/health.pdf || exit 1

# 设置默认命令
CMD ["bash", "-c", "source /etc/profile.d/tinytex.sh && xelatex --version"]
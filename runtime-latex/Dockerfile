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
    echo "TINYTEX_ARCH=${TINYTEX_ARCH}" > /tmp/arch.env && \
    echo "export TINYTEX_ARCH=${TINYTEX_ARCH}" >> /etc/environment

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

# 步骤1：使用简化的TinyTeX安装方法
RUN set -e && \
    . /tmp/arch.env && \
    echo "Architecture: ${TINYTEX_ARCH}" && \
    echo "Installing TinyTeX using simplified method..." && \
    # 创建安装目录
    mkdir -p /root/.TinyTeX && \
    # 下载并安装TinyTeX
    cd /tmp && \
    wget --timeout=300 --tries=3 -O install-tinytex.sh \
        "https://yihui.org/tinytex/install-bin-unix.sh" && \
    # 设置环境变量以确保正确安装
    export TINYTEX_DIR="/root/.TinyTeX" && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    # 运行安装脚本
    echo "Running TinyTeX installation script..." && \
    sh install-tinytex.sh && \
    # 验证安装
    echo "Verifying installation..." && \
    ls -la /root/.TinyTeX/ && \
    ls -la /root/.TinyTeX/bin/ && \
    # 清理安装文件
    rm -f install-tinytex.sh && \
    echo "TinyTeX installation completed."

# 步骤2：验证 TinyTeX 安装并配置 tlmgr
RUN set -e && \
    . /tmp/arch.env && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    echo "Verifying TinyTeX installation..." && \
    echo "Current PATH: $PATH" && \
    echo "Architecture: ${TINYTEX_ARCH}" && \
    # 查找tlmgr的实际位置
    echo "Searching for tlmgr..." && \
    find /root/.TinyTeX -name "tlmgr" -type f 2>/dev/null || echo "tlmgr not found" && \
    # 尝试直接运行tlmgr
    if command -v tlmgr >/dev/null 2>&1; then \
        echo "tlmgr found in PATH, testing..." && \
        tlmgr --version && \
        echo "Configuring tlmgr..." && \
        tlmgr option autobackup 0 && \
        echo "TinyTeX verification completed."; \
    else \
        echo "tlmgr not found in PATH, checking installation..." && \
        ls -la /root/.TinyTeX/ && \
        echo "Installation may have failed, but continuing..." && \
        exit 1; \
    fi

# 步骤3：安装基础 LaTeX 包（如果tlmgr可用）
RUN set -e && \
    . /tmp/arch.env && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    echo "Installing basic LaTeX packages..." && \
    if command -v tlmgr >/dev/null 2>&1; then \
        echo "tlmgr available, installing packages..." && \
        # 安装基础包（允许失败）
        (tlmgr install latex-bin || echo "Warning: latex-bin installation failed") && \
        (tlmgr install xetex || echo "Warning: xetex installation failed") && \
        echo "Package installation completed."; \
    else \
        echo "tlmgr not available, skipping package installation"; \
    fi

# 步骤4：清理和优化（跳过字体包安装以简化构建）
RUN set -e && \
    . /tmp/arch.env && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    echo "Performing cleanup to reduce image size..." && \
    # 清理不必要的文件
    rm -rf /root/.TinyTeX/texmf-dist/doc \
           /root/.TinyTeX/texmf-dist/source \
           /root/.TinyTeX/tlpkg/backups \
           /root/.TinyTeX/tlpkg/temp \
           /tmp/* 2>/dev/null || echo "Some cleanup operations failed, continuing..." && \
    echo "Cleanup completed."



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

# 根据目标架构设置 TinyTeX 二进制路径并设置环境变量
RUN case "${TARGETARCH}" in \
        amd64) TINYTEX_ARCH="x86_64-linux" ;; \
        arm64) TINYTEX_ARCH="aarch64-linux" ;; \
        arm) TINYTEX_ARCH="armhf-linux" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    echo "export PATH=\"/usr/local/TinyTeX/bin/${TINYTEX_ARCH}:\$PATH\"" > /etc/profile.d/tinytex.sh && \
    chmod +x /etc/profile.d/tinytex.sh && \
    echo "PATH=/usr/local/TinyTeX/bin/${TINYTEX_ARCH}:\$PATH" >> /etc/environment && \
    echo "TINYTEX_ARCH=${TINYTEX_ARCH}" >> /etc/environment

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
    mkdir -p /app /home/appuser /home/appuser/tmp && \
    chown -R appuser:nodejs /app /home/appuser && \
    chmod 755 /home/appuser/tmp

# 设置动态 PATH 环境变量（架构特定）
ENV PATH="/usr/local/TinyTeX/bin/x86_64-linux:/usr/local/TinyTeX/bin/aarch64-linux:/usr/local/TinyTeX/bin/armhf-linux:$PATH"

# 创建工作目录
WORKDIR /app

# 切换到非 root 用户，增强安全性
USER appuser

# 创建简单的 LaTeX 测试文件用于健康检查
RUN echo '\documentclass{article}\begin{document}Hello LaTeX!\end{document}' > /tmp/test.tex

# 添加健康检查 - 测试实际的 LaTeX 编译功能
HEALTHCHECK --interval=30s --timeout=15s --start-period=10s --retries=3 \
  CMD source /etc/profile.d/tinytex.sh && \
      xelatex --version && \
      echo '\documentclass{article}\begin{document}Health Check\end{document}' > /home/appuser/tmp/health.tex && \
      xelatex -interaction=nonstopmode -output-directory=/home/appuser/tmp /home/appuser/tmp/health.tex >/dev/null 2>&1 && \
      test -f /home/appuser/tmp/health.pdf || exit 1

# 设置默认命令
CMD ["bash", "-c", "source /etc/profile.d/tinytex.sh && xelatex --version"]
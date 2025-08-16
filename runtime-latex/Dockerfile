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

# 步骤1：直接下载并安装最新版本的TinyTeX
RUN set -e && \
    . /tmp/arch.env && \
    echo "Architecture: ${TINYTEX_ARCH}" && \
    echo "Installing TinyTeX directly from official source..." && \
    # 创建安装目录
    mkdir -p /root/.TinyTeX && \
    cd /tmp && \
    # 下载最新的install-tl安装器
    echo "Downloading TeX Live installer..." && \
    wget --timeout=300 --tries=3 -O install-tl-unx.tar.gz \
        "https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz" && \
    tar -xzf install-tl-unx.tar.gz && \
    cd install-tl-* && \
    # 创建TinyTeX配置文件
    cat > tinytex.profile << 'EOF'
selected_scheme scheme-infraonly
TEXDIR /root/.TinyTeX
TEXMFCONFIG ~/.texlive/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL /root/.TinyTeX/texmf-local
TEXMFSYSCONFIG /root/.TinyTeX/texmf-config
TEXMFSYSVAR /root/.TinyTeX/texmf-var
TEXMFVAR ~/.texlive/texmf-var
binary_x86_64-linux 1
binary_aarch64-linux 1
binary_armhf-linux 1
collection-basic 1
collection-latex 1
collection-latexrecommended 1
collection-fontsrecommended 1
instopt_adjustpath 0
instopt_adjustrepo 1
instopt_letter 0
instopt_portable 0
instopt_write18_restricted 1
tlpdbopt_autobackup 0
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 0
tlpdbopt_file_assocs 0
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_post_code 1
tlpdbopt_sys_bin /usr/local/bin
tlpdbopt_sys_info /usr/local/share/info
tlpdbopt_sys_man /usr/local/share/man
tlpdbopt_w32_multi_user 0
EOF
    # 执行安装
    echo "Running TeX Live installation..." && \
    ./install-tl --profile=tinytex.profile --no-interaction && \
    echo "TinyTeX installation completed." && \
    # 清理安装文件
    cd / && rm -rf /tmp/install-tl* && \
    echo "Installation files cleaned up."

# 步骤2：验证 TinyTeX 安装并配置 tlmgr
RUN set -e && \
    . /tmp/arch.env && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    echo "Verifying TinyTeX installation..." && \
    echo "PATH: $PATH" && \
    echo "TinyTeX directory contents:" && \
    ls -la /root/.TinyTeX/bin/ || echo "No bin directory found" && \
    ls -la /root/.TinyTeX/bin/${TINYTEX_ARCH}/ || echo "No architecture-specific bin directory found" && \
    # 验证tlmgr是否存在并可执行
    if [ -f "/root/.TinyTeX/bin/${TINYTEX_ARCH}/tlmgr" ]; then \
        echo "tlmgr found, testing..." && \
        /root/.TinyTeX/bin/${TINYTEX_ARCH}/tlmgr --version && \
        echo "Configuring tlmgr..." && \
        /root/.TinyTeX/bin/${TINYTEX_ARCH}/tlmgr option autobackup 0 && \
        /root/.TinyTeX/bin/${TINYTEX_ARCH}/tlmgr option && \
        echo "TinyTeX verification and configuration completed."; \
    else \
        echo "tlmgr not found in expected location" && \
        find /root/.TinyTeX -name "tlmgr" -type f 2>/dev/null || echo "tlmgr not found anywhere" && \
        exit 1; \
    fi

# 步骤3：安装基础 LaTeX 包（保守安装，逐个处理）
RUN set -e && \
    . /tmp/arch.env && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    echo "Installing basic LaTeX packages..." && \
    # 更新包数据库
    tlmgr update --self --all || echo "Warning: tlmgr update failed, continuing..." && \
    # 安装基础包
    tlmgr install enumitem || echo "Warning: enumitem package installation failed" && \
    tlmgr install titlesec || echo "Warning: titlesec package installation failed" && \
    tlmgr install parskip || echo "Warning: parskip package installation failed" && \
    tlmgr install xetex || echo "Warning: xetex package installation failed" && \
    echo "Basic LaTeX packages installation completed."

# 步骤4：安装字体和中文支持包（可选，允许失败）
RUN set -e && \
    . /tmp/arch.env && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    echo "Installing font and Chinese support packages..." && \
    (tlmgr install fontawesome5 || echo "Warning: fontawesome5 package not available, skipping") && \
    (tlmgr install ctex || echo "Warning: ctex package installation failed, skipping") && \
    (tlmgr install fandol || echo "Warning: fandol package installation failed, skipping") && \
    echo "Font and Chinese support packages installation completed."

# 步骤5：更新格式文件和清理
RUN set -e && \
    . /tmp/arch.env && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    echo "Updating format files..." && \
    (fmtutil-sys --all || echo "Warning: format file update had issues, continuing") && \
    echo "Performing cleanup to reduce image size..." && \
    rm -rf /root/.TinyTeX/texmf-dist/doc \
           /root/.TinyTeX/texmf-dist/source \
           /root/.TinyTeX/tlpkg/backups \
           /root/.TinyTeX/tlpkg/temp \
           /root/.TinyTeX/install-tl.log \
           /tmp/* && \
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
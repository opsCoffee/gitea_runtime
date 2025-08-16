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

# 步骤1：使用最新的 TinyTeX 安装方法
RUN set -e && \
    . /tmp/arch.env && \
    echo "Architecture: ${TINYTEX_ARCH}" && \
    echo "Installing TinyTeX using latest method..." && \
    # 创建安装目录
    mkdir -p /root/.TinyTeX && \
    cd /tmp && \
    # 下载最新的 TeX Live 安装器
    echo "Downloading TeX Live installer..." && \
    wget --timeout=300 --tries=3 -O install-tl-unx.tar.gz \
        "https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz" && \
    tar -xzf install-tl-unx.tar.gz && \
    cd install-tl-* && \
    # 创建 TinyTeX 配置文件
    echo "Creating TinyTeX profile..." && \
    printf '%s\n' \
        'selected_scheme scheme-infraonly' \
        'TEXDIR /root/.TinyTeX' \
        'TEXMFCONFIG ~/.texlive/texmf-config' \
        'TEXMFHOME ~/texmf' \
        'TEXMFLOCAL /root/.TinyTeX/texmf-local' \
        'TEXMFSYSCONFIG /root/.TinyTeX/texmf-config' \
        'TEXMFSYSVAR /root/.TinyTeX/texmf-var' \
        'TEXMFVAR ~/.texlive/texmf-var' \
        'binary_x86_64-linux 1' \
        'binary_aarch64-linux 1' \
        'binary_armhf-linux 1' \
        'collection-basic 1' \
        'collection-latex 1' \
        'collection-latexrecommended 1' \
        'collection-fontsrecommended 1' \
        'instopt_adjustpath 0' \
        'instopt_adjustrepo 1' \
        'instopt_letter 0' \
        'instopt_portable 0' \
        'instopt_write18_restricted 1' \
        'tlpdbopt_autobackup 0' \
        'tlpdbopt_backupdir tlpkg/backups' \
        'tlpdbopt_create_formats 1' \
        'tlpdbopt_desktop_integration 0' \
        'tlpdbopt_file_assocs 0' \
        'tlpdbopt_generate_updmap 0' \
        'tlpdbopt_install_docfiles 0' \
        'tlpdbopt_install_srcfiles 0' \
        'tlpdbopt_post_code 1' \
        'tlpdbopt_sys_bin /usr/local/bin' \
        'tlpdbopt_sys_info /usr/local/share/info' \
        'tlpdbopt_sys_man /usr/local/share/man' \
        'tlpdbopt_w32_multi_user 0' \
        > tinytex.profile && \
    # 运行安装
    echo "Running TeX Live installation..." && \
    ./install-tl --profile=tinytex.profile --no-interaction && \
    # 验证安装
    echo "Verifying installation..." && \
    ls -la /root/.TinyTeX/ && \
    ls -la /root/.TinyTeX/bin/ && \
    # 清理安装文件
    cd /tmp && rm -rf install-tl-* install-tl-unx.tar.gz && \
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
    find /root/.TinyTeX -name "tlmgr" -type f 2>/dev/null && \
    # 验证 tlmgr 可执行
    echo "Testing tlmgr..." && \
    tlmgr --version && \
    echo "Configuring tlmgr..." && \
    tlmgr option autobackup 0 && \
    tlmgr option docfiles 0 && \
    tlmgr option srcfiles 0 && \
    echo "TinyTeX verification and configuration completed."

# 步骤3：安装基础 LaTeX 包
RUN set -e && \
    . /tmp/arch.env && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    echo "Installing essential LaTeX packages..." && \
    # 安装核心包
    tlmgr install latex-bin xetex luatex && \
    # 安装常用包
    tlmgr install amsmath amsfonts amssymb geometry fancyhdr graphicx xcolor && \
    # 安装中文支持包
    tlmgr install ctex xecjk fontspec && \
    # 验证安装
    echo "Verifying package installation..." && \
    xelatex --version && \
    lualatex --version && \
    echo "Package installation completed."

# 步骤4：清理和优化
RUN set -e && \
    . /tmp/arch.env && \
    export PATH="/root/.TinyTeX/bin/${TINYTEX_ARCH}:$PATH" && \
    echo "Performing cleanup to reduce image size..." && \
    # 更新 tlmgr 数据库
    tlmgr update --self --all || echo "Warning: tlmgr update failed" && \
    # 清理不必要的文件
    rm -rf /root/.TinyTeX/texmf-dist/doc \
           /root/.TinyTeX/texmf-dist/source \
           /root/.TinyTeX/tlpkg/backups \
           /root/.TinyTeX/tlpkg/temp \
           /tmp/* && \
    # 创建测试文件验证安装
    echo '\documentclass{article}\usepackage{ctex}\begin{document}测试 TinyTeX 安装\end{document}' > /tmp/test.tex && \
    xelatex -interaction=nonstopmode /tmp/test.tex && \
    test -f test.pdf && \
    rm -f test.* /tmp/test.tex && \
    echo "TinyTeX installation and cleanup completed successfully."



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
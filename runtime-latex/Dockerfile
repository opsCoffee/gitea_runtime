# =================================================================
# Gitea Runtime: LaTeX 文档处理运行时
# =================================================================

# 构建参数
ARG NODE_VERSION=20.17.0
ARG TINYTEX_VERSION=2024.01
ARG GITEA_VERSION=dev
ARG BUILD_DATE

# =================================================================
# 第一阶段：构建精简的 TinyTeX 环境
# =================================================================
FROM debian:12-slim AS tex-builder

ENV DEBIAN_FRONTEND=noninteractive

# 安装系统级依赖（包括 XeTeX 运行时依赖）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        perl \
        ca-certificates \
        gnupg2 \
        # XeTeX 运行时依赖
        libfontconfig1 \
        libfreetype6 \
        fontconfig \
        fonts-liberation \
        # 添加基本的中文字体支持
        fonts-noto-cjk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 步骤1：使用官方 TinyTeX 安装脚本（更简单可靠）
RUN set -e && \
    echo "Installing TinyTeX using official script..." && \
    # 使用官方 TinyTeX 安装脚本
    wget -qO- "https://yihui.org/tinytex/install-bin-unix.sh" | sh && \
    # 验证安装
    echo "Verifying TinyTeX installation..." && \
    export PATH="$HOME/.TinyTeX/bin/x86_64-linux:$PATH" && \
    tlmgr --version && \
    echo "TinyTeX installation completed."

# 步骤2：配置 tlmgr 并安装基础包
RUN set -e && \
    export PATH="$HOME/.TinyTeX/bin/x86_64-linux:$PATH" && \
    echo "Configuring tlmgr..." && \
    # 配置 tlmgr 选项
    tlmgr option autobackup 0 && \
    tlmgr option docfiles 0 && \
    tlmgr option srcfiles 0 && \
    # 更新包数据库
    tlmgr update --self && \
    echo "tlmgr configuration completed."

# 步骤3：安装必要的 LaTeX 包（容错安装，避免单个包失败影响整体）
RUN export PATH="$HOME/.TinyTeX/bin/x86_64-linux:$PATH" && \
    echo "Installing essential LaTeX packages..." && \
    # 定义安装函数，允许单个包失败
    install_package() { \
        echo "Installing $1..."; \
        tlmgr install "$1" || echo "Warning: Failed to install $1, continuing..."; \
    } && \
    # 安装基础 LaTeX 包
    install_package latex-bin && \
    # 安装 XeTeX 和相关包
    install_package xetex && \
    # 安装字体支持包
    install_package fontspec && \
    # 安装常用数学包（分别安装，避免 amssymb 不存在的问题）
    install_package amsmath && \
    install_package amsfonts && \
    # 注意：amssymb 在某些 TinyTeX 仓库中可能不存在，amsfonts 已包含相关符号
    # install_package amssymb && \
    # 安装页面布局包
    install_package geometry && \
    install_package fancyhdr && \
    # 安装图形支持包
    install_package graphicx && \
    install_package xcolor && \
    echo "Essential packages installation completed."

# 步骤4：安装中文支持包
RUN export PATH="$HOME/.TinyTeX/bin/x86_64-linux:$PATH" && \
    echo "Installing Chinese support packages..." && \
    # 定义安装函数，允许单个包失败
    install_package() { \
        echo "Installing $1..."; \
        tlmgr install "$1" || echo "Warning: Failed to install $1, continuing..."; \
    } && \
    # 安装中文支持的核心包
    install_package xecjk && \
    install_package ctex && \
    echo "Chinese support packages installation completed."

# 步骤5：清理和验证
RUN set -e && \
    export PATH="$HOME/.TinyTeX/bin/x86_64-linux:$PATH" && \
    echo "Performing cleanup and verification..." && \
    # 清理不必要的文件
    rm -rf $HOME/.TinyTeX/texmf-dist/doc \
           $HOME/.TinyTeX/texmf-dist/source \
           $HOME/.TinyTeX/tlpkg/backups \
           $HOME/.TinyTeX/tlpkg/temp && \
    # 验证安装
    echo "Verifying installation..." && \
    tlmgr --version && \
    xelatex --version && \
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
    TZ=Asia/Shanghai \
    PATH="/usr/local/TinyTeX/bin/x86_64-linux:$PATH"

# 安装 TeX 运行所需的动态链接库和系统工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        perl \
        libfontconfig1 \
        libfreetype6 \
        fontconfig \
        fonts-liberation \
        fonts-noto-cjk \
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

# 创建工作目录
WORKDIR /app

# 切换到非 root 用户，增强安全性
USER appuser

# 添加简化的健康检查 - 只检查命令可用性
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD xelatex --version >/dev/null 2>&1 && tlmgr --version >/dev/null 2>&1 || exit 1

# 设置默认命令
CMD ["bash", "-c", "xelatex --version && echo 'TinyTeX is ready!'"]
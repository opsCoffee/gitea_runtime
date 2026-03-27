# =================================================================
# Gitea Runtime: Claude Code 开发环境
# =================================================================

# 使用参数化的Node.js版本
ARG NODE_VERSION=22.6.0
FROM node:${NODE_VERSION}-alpine

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.title="Gitea Runtime Claude Code" \
      org.opencontainers.image.description="Claude Code development environment with MCP servers and Git hooks for AI-assisted development" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.documentation="https://git.httpx.online/kenyon/gitea-runtime/src/branch/main/runtime-claudecode/README.md" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://git.httpx.online/kenyon/gitea-runtime" \
      maintainer="kenyon <kenyon@noreply.localhost>"

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 安装必要工具并设置时区
RUN set -eux; \
    # 更新包索引并安装必要工具
    apk update && \
    apk add --no-cache \
        dos2unix \
        curl \
        vim \
        bash \
        git \
        openssh-client \
        tzdata \
        rsync && \
    # 设置时区
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    # 清理缓存
    rm -rf /var/cache/apk/* && \
    # 验证安装
    node --version && \
    npm --version

# 安装 Claude Code 及相关配置
RUN echo "=== 安装 Claude Code ===" && \
    npm install -g @anthropic-ai/claude-code@2.0.26 && \
    echo "=== 配置 Claude Code 环境 ===" && \
    export HOME=/home/nextjs && mkdir -p "$HOME" && rm -rf "$HOME/.claude" "$HOME/.claude.json" && \
    git clone --depth 1 https://github.com/kenyon-wong/.claude.git "$HOME/.claude" && \
    echo "=== 安装 MCP 服务器 ===" && \
    claude mcp add -s user -t http context7 https://mcp.context7.com/mcp && \
    claude mcp add -s user -t http grep https://mcp.grep.app && \
    claude mcp add -s user -t http deepwiki https://mcp.deepwiki.com/mcp && \
    claude mcp add-json "sequential-thinking" '{"command":"npx","args":["-y","@modelcontextprotocol/server-sequential-thinking"]}' && \
    chown -R nextjs:nodejs "$HOME" && \
    echo "=== Claude Code 配置完成 ==="

# 安装运行时辅助脚本
COPY install-git-hook.sh /usr/local/bin/install-claude-git-hook
RUN chmod +x /usr/local/bin/install-claude-git-hook

# 设置工作目录
WORKDIR /app

# 更改工作目录所有权
RUN chown -R nextjs:nodejs /app

# 切换到非root用户
USER nextjs

# 配置 Git
RUN git config --global pull.rebase true && \
    # 设置 UTF-8 编码以避免中文乱码
    git config --global core.quotepath false && \
    git config --global i18n.commitencoding utf-8 && \
    git config --global i18n.logoutputencoding utf-8

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node --version || exit 1

# 设置默认命令
CMD ["bash"]

# 第一阶段：构建 TinyTeX 环境
FROM debian:stable-slim AS tex-builder

SHELL ["/bin/bash", "-c"]

# 安装依赖并清理
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    perl \
    fontconfig \
    libfontconfig1-dev \
    libfreetype6-dev \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 检查 Perl 模块
RUN perl -mFile::Find -e 1

# 安装 TinyTeX 并清理临时文件
RUN wget -qO- "https://yihui.org/tinytex/install-bin-unix.sh" | sh && \
    rm -rf /tmp/*

# 设置环境变量
ENV PATH="/root/bin:/root/.TinyTeX/bin/x86_64-linux:${PATH}"

# 更新和安装 TeX 包，并清理缓存
RUN tlmgr --version && \
    tlmgr update --self --all && \
    tlmgr install enumitem titlesec fontawesome5 parskip ctex && \
    tlmgr install noto fandol && \
    tlmgr path remove && \
    rm -rf /root/.texlive2023/tlpkg/backups /root/.texlive2023/tlpkg/temp

# 清理不必要的依赖
RUN apt-get purge -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# 第二阶段：使用 node:lts-slim 作为最终镜像
FROM node:lts-slim

# 安装 Perl 和 libfontconfig
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    perl \
    libfontconfig1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 从 tex-builder 阶段复制 TinyTeX 相关文件
COPY --from=tex-builder /root/.TinyTeX /root/.TinyTeX
COPY --from=tex-builder /root/bin /root/bin

# 设置环境变量
ENV PATH="/root/bin:/root/.TinyTeX/bin/x86_64-linux:${PATH}"

# 设置工作目录
WORKDIR /workdir

# 验证 tlmgr 是否可用
RUN tlmgr --version

# 设置默认命令
CMD ["tlmgr", "--help"]

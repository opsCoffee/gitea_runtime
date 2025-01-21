# 第一阶段：构建 TinyTeX 环境
FROM debian:12-slim AS tex-builder

SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget perl fontconfig libfontconfig1-dev libfreetype6-dev ca-certificates && \
    wget -qO- "https://yihui.org/tinytex/install-bin-unix.sh" | sh && \
    export PATH="/root/bin:/root/.TinyTeX/bin/x86_64-linux:$PATH" && \
    tlmgr update --self --all && \
    tlmgr install enumitem titlesec fontawesome5 parskip ctex noto fandol && \
    tlmgr path remove && \
    apt-get purge -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /root/.TinyTeX/tlpkg/backups /root/.TinyTeX/tlpkg/temp

# 第二阶段：使用 Node 镜像
FROM node:20-bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      perl libfontconfig1 libfreetype6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=tex-builder /root/.TinyTeX /usr/local/TinyTeX
ENV PATH="/usr/local/TinyTeX/bin/x86_64-linux:$PATH"

RUN node -v && which tlmgr && tlmgr --version

WORKDIR /workdir
CMD ["tlmgr", "--help"]

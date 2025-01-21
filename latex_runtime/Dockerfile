FROM debian:stable-slim

SHELL ["/bin/bash", "-c"]

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

RUN perl -mFile::Find -e 1

RUN wget -qO- "https://yihui.org/tinytex/install-bin-unix.sh" | sh

ENV PATH="/root/bin:/root/.TinyTeX/bin/x86_64-linux:${PATH}"

RUN tlmgr --version && \
    tlmgr update --self --all && \
    tlmgr install enumitem titlesec fontawesome5 parskip ctex

RUN apt-get purge -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /workdir

CMD ["tlmgr", "--help"]
# Use the latest stable Alpine Linux image
FROM alpine:latest

# Set environment variables
ENV TEXMFHOME=/usr/share/texmf-dist

# Enable community and testing repositories and install necessary base packages
RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk add texmf-dist texlive texmaker font-noto-cjk texlive-xetex wget perl xz tar

# Download and install TeX Live
RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    tar -xzf install-tl-unx.tar.gz && \
    cd install-tl-20* && \
    printf "selected_scheme scheme-full\n" > texlive.profile && \
    ./install-tl --profile texlive.profile && \
    ln -s /usr/local/texlive/2023/bin/x86_64-linux/* /usr/bin/ && \
    cd .. && \
    rm -rf install-tl-unx.tar.gz install-tl-20*

# Set up working directory
WORKDIR /workspace

# Set the default command to bash (or sh)
CMD ["/bin/sh"]


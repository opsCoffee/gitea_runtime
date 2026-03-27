# =================================================================
# Gitea Runtime: Maven Java 构建环境
# =================================================================

# 基础镜像：BellSoft Liberica JDK 17 with JavaFX (Debian Slim)
ARG MAVEN_VERSION=3.9.12
ARG MAVEN_SHA512=0a1be79f02466533fc1a80abbef8796e4f737c46c6574ede5658b110899942a94db634477dfd3745501c80aef9aac0d4f841d38574373f7e2d24cce89d694f70
ARG MAVEN_DIST_BASE_URL=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven
FROM bellsoft/liberica-openjdk-debian:17

ARG MAVEN_VERSION=3.9.12
ARG MAVEN_SHA512=0a1be79f02466533fc1a80abbef8796e4f737c46c6574ede5658b110899942a94db634477dfd3745501c80aef9aac0d4f841d38574373f7e2d24cce89d694f70
ARG MAVEN_DIST_BASE_URL=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven

# 使用 OCI 标准标签
LABEL org.opencontainers.image.authors="kenyon <kenyon@noreply.localhost>" \
      org.opencontainers.image.title="Gitea Runtime Maven" \
      org.opencontainers.image.description="Maven build environment for Java projects with Liberica JDK 17 and Node.js 20" \
      org.opencontainers.image.source="https://git.httpx.online/kenyon/gitea-runtime" \
      org.opencontainers.image.vendor="Gitea Runtime Project" \
      org.opencontainers.image.licenses="MIT"

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    PATH=$JAVA_HOME/bin:$PATH

# 安装构建常用工具
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      git \
      bash \
      ca-certificates \
      gnupg \
      xz-utils \
      tar \
      tzdata \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
       | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && chmod 0644 /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list \
    && rm -rf /var/lib/apt/lists/* \
    # 设置时区
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && curl -fsSL ${MAVEN_DIST_BASE_URL}/${MAVEN_VERSION}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
       -o /tmp/maven.tar.gz \
    && echo "${MAVEN_SHA512}  /tmp/maven.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/maven \
    && tar -xzf /tmp/maven.tar.gz -C /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
    && rm -f /tmp/maven.tar.gz \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@latest \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /root/.npm

# 创建非 root 用户
RUN groupadd -g 1001 maven && \
    useradd -r -m -u 1001 -g maven appuser && \
    mkdir -p /workspace /home/appuser/.m2/repository && \
    chown -R appuser:maven /workspace /home/appuser

# 设置工作目录
WORKDIR /workspace

# 切换到非 root 用户
USER appuser

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD java -version >/dev/null 2>&1 && mvn --version >/dev/null 2>&1 || exit 1

# 默认执行 /bin/bash
CMD ["/bin/bash"]

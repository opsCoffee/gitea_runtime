# 基础镜像：BellSoft Liberica JDK 17 with JavaFX (Debian Slim)
FROM bellsoft/liberica-openjdk-debian:17

# 设置环境变量
ENV LANG=C.UTF-8 \
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
    && rm -rf /var/lib/apt/lists/* \
    && MAVEN_VERSION=$(curl -s https://dlcdn.apache.org/maven/maven-3/ \
    | grep -Eo 'href="[0-9.]+' | sed 's/href="//' | sort -V | tail -1) \
    && curl -fsSL https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
       -o /tmp/maven.tar.gz \
    && mkdir -p /usr/share/maven \
    && tar -xzf /tmp/maven.tar.gz -C /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
    && rm -f /tmp/maven.tar.gz \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@latest \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /root/.npm

# 默认工作目录
WORKDIR /workspace

# 默认执行 /bin/bash
CMD ["/bin/bash"]
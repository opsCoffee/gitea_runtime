# =======================================================================================
# STAGE 1: Builder - 准备所有工具和依赖
# 我们在这一阶段下载和解压所有内容，避免在最终镜像中留下不必要的下载缓存和工具。
# =======================================================================================
FROM debian:bookworm-slim AS builder

# --- 1. 定义版本参数 ---
# 使用 ARG 可以方便地在构建时修改版本，例如: docker build --build-arg MAVEN_VERSION=3.9.8 -t my-image .
ARG NODE_VERSION=20
ARG MAVEN_VERSION=3.9.7
ARG GRADLE_VERSION=8.8

# --- 2. 安装临时依赖 ---
# --no-install-recommends 是一个关键优化，避免安装非必需的推荐包。
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl unzip ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# --- 3. 安装 Node.js (为 Gitea CLI 提供 JS 环境) ---
# 从 NodeSource 安装可以确保版本的稳定和官方性。
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# --- 5. 下载 OpenJDK 17 ---
# 我们选择从 Adoptium (Eclipse Temurin) 下载，它提供纯净的 OpenJDK 构建。
RUN curl -L "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz" -o /tmp/openjdk.tar.gz && \
    mkdir -p /opt/jdk && \
    tar -xzf /tmp/openjdk.tar.gz -C /opt/jdk --strip-components=1

# --- 6. 下载 Maven ---
RUN curl -L "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o /tmp/maven.tar.gz && \
    mkdir -p /opt/maven && \
    tar -xzf /tmp/maven.tar.gz -C /opt/maven --strip-components=1

# --- 7. 下载 Gradle ---
RUN curl -L "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip && \
    mkdir -p /opt/gradle && \
    unzip -d /opt/gradle /tmp/gradle.zip && \
    mv /opt/gradle/gradle-${GRADLE_VERSION}/* /opt/gradle && \
    rmdir /opt/gradle/gradle-${GRADLE_VERSION}

# =======================================================================================
# STAGE 2: Final Image - 构建最终的、干净的镜像
# 这是最终交付的镜像。它只包含运行和构建所必需的组件。
# =======================================================================================
FROM debian:bookworm-slim

LABEL maintainer="kenyon <kenyon@noreply.localhost>"
LABEL description="A Docker image with JDK 17, Maven, Gradle, Node.js, and Gitea CLI for building Burp Suite extensions."

# --- 1. 设置环境变量 ---
# 设置 Locale 避免一些工具出现警告。
# 设置 JAVA_HOME, MAVEN_HOME, GRADLE_HOME 并将它们的 bin 目录添加到 PATH。
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk \
    MAVEN_HOME=/opt/maven \
    GRADLE_HOME=/opt/gradle \
    PATH=/usr/lib/jvm/java-17-openjdk/bin:/opt/maven/bin:/opt/gradle/bin:/usr/local/bin:$PATH

# --- 2. 安装最精简的运行时依赖 ---
# 只安装 git 和 ca-certificates。其他工具将从 builder 阶段拷贝。
RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    # 清理 apt 缓存，减小镜像体积
    rm -rf /var/lib/apt/lists/*

# --- 3. 从 builder 阶段拷贝所有预处理好的工具 ---
COPY --from=builder /opt/jdk ${JAVA_HOME}
COPY --from=builder /opt/maven ${MAVEN_HOME}
COPY --from=builder /opt/gradle ${GRADLE_HOME}
COPY --from=builder /usr/bin/node /usr/bin/node
COPY --from=builder /usr/lib/node_modules/ /usr/lib/node_modules/

# --- 4. 安全实践：创建非 root 用户 ---
# 在 CI/CD 环境中，使用非 root 用户运行容器是一个重要的安全措施。
# 我们创建一个名为 `builder` 的用户。
RUN groupadd --gid 1001 builder && \
    useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home builder

# --- 5. 设置工作目录并切换用户 ---
WORKDIR /workspace
USER builder

# --- 6. 验证安装 ---
RUN echo "Java version:" && java -version && \
    echo "Node version:" && node -v && \
    echo "Maven version:" && mvn -v && \
    echo "Gradle version:" && gradle -v

# --- 7. 设置默认入口点 ---
# 将默认命令设置为 bash，这样 `docker run -it <image>` 会直接进入一个交互式 shell，
CMD ["/bin/bash"]
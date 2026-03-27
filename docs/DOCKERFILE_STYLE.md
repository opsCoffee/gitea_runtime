# Dockerfile 风格规范

## 当前结论

当前仓库的 Dockerfile 在以下方面已经基本一致：
- 都有清晰的文件头说明
- 都使用 OCI 标签
- 都显式设置工作目录、非 root 用户、健康检查和默认命令
- 多阶段镜像都已经写出阶段边界

当前仍存在的主要风格分叉：
- OCI 标签完整度不一致
- 注释命名和分段粒度不一致
- 构建参数声明位置不一致
- 简单镜像与复杂镜像的 `RUN` 风格不一致

本规范的目标不是机械统一所有细节，而是统一可读性和维护习惯，同时允许 runtime 保留必要差异。

## 统一要求

### 1. 文件结构

推荐顺序：
1. 文件头说明
2. 构建参数
3. `FROM`
4. 标签
5. 环境变量
6. 依赖安装
7. 文件复制
8. 用户与目录
9. `WORKDIR`
10. `USER`
11. `HEALTHCHECK`
12. `CMD`

### 2. 构建参数

- 仅用于 `FROM` 的参数可放在首个 `FROM` 之前。
- 需要在具体 stage 内使用的参数，必须在该 stage 内重新声明。
- 不要依赖“前一个 stage 的 ARG 还能继续用”这种隐含行为。

### 3. 标签

所有镜像至少应包含以下 OCI 标签：
- `org.opencontainers.image.authors`
- `org.opencontainers.image.title`
- `org.opencontainers.image.description`
- `org.opencontainers.image.source`
- `org.opencontainers.image.vendor`
- `org.opencontainers.image.licenses`

在存在统一构建参数时，优先补齐：
- `org.opencontainers.image.version`
- `org.opencontainers.image.created`
- `org.opencontainers.image.documentation`
- `org.opencontainers.image.url`

不再推荐额外使用 `maintainer` 这种非 OCI 元数据。

### 4. 环境变量

公共顺序建议：
1. `LANG`
2. `LANGUAGE`
3. `LC_ALL`
4. `TZ`
5. 运行时特有变量

如果某个基础镜像对 locale 有特殊限制，可以保留差异，但应在 Dockerfile 或 README 中说明原因。

### 5. RUN 风格

- 简单 Alpine 镜像允许使用 `RUN ... && ...` 的紧凑写法。
- 多步骤、带条件或函数的复杂构建逻辑，统一使用 `set -e` 或 `set -eux` 的分段写法。
- 允许多阶段镜像比简单镜像更详细，不要求为追求形式统一而牺牲可读性。

### 6. 允许保留的差异

以下差异属于 runtime 特性，不应强行统一：
- 基础镜像类型和版本锁定方式
- 多阶段与单阶段构建
- 用户名和用户组名
- 默认命令
- 健康检查的具体命令
- 运行时特有依赖和额外目录结构

## 当前仓库的建议做法

- 简单运行时：保持文件短小，重点统一标签、注释和 section 顺序
- 复杂运行时：保留阶段化注释和显式验证步骤，不为了“行数统一”压缩逻辑
- 新增 Dockerfile 时，优先复用已有注释与标签顺序，而不是再引入第三套风格

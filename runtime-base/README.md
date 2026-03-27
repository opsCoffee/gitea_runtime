# 基础 Node.js 运行时

## 定位

作为通用 Node.js 任务的基础环境，也可作为其他 runtime 的参考基线。

## 镜像信息

| 项目 | 值 |
| --- | --- |
| 基础镜像 | `node:22.6.0-alpine` |
| 默认用户 | `nextjs` |
| 工作目录 | `/app` |
| 默认命令 | `node` |
| 关键工具 | `node`, `npm`, `git`, `bash` |

## 构建

```bash
docker buildx build -t gitea-runtime-base:latest ./runtime-base
./scripts/runtimectl.sh build --only base
```

## 最小验证

```bash
./scripts/runtimectl.sh test --only base
```

## 常用用法

```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-base:latest node index.js

docker run --rm -v "$(pwd):/workspace" -w /workspace \
  gitea-runtime-base:latest npm install
```

作为基础镜像使用：

```dockerfile
FROM git.httpx.online/kenyon/gitea-runtime-base:latest
WORKDIR /app
COPY . .
CMD ["node", "index.js"]
```

## 在 Gitea Actions 中使用

```yaml
jobs:
  node-task:
    runs-on: ubuntu-latest
    container:
      image: git.httpx.online/kenyon/gitea-runtime-base:latest
    steps:
      - uses: actions/checkout@v4
      - run: node index.js
```

## 预装工具与环境

- 环境变量：`LANG`、`LANGUAGE`、`LC_ALL`、`TZ`
- 运行工具：`node`、`npm`
- 辅助工具：`bash`、`curl`、`vim`、`git`、`openssh-client`

## 安全与维护

- 以非 root 用户 `nextjs` 运行
- 默认包含健康检查
- Dockerfile 风格维护遵循 [docs/DOCKERFILE_STYLE.md](../docs/DOCKERFILE_STYLE.md)

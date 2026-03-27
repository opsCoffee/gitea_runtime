# AGENTS.md

本文件用于给后续进入本仓库的代理提供稳定、可执行的项目约束。内容基于当前仓库已经落地并验证过的做法，而不是泛化建议。

## 1. 沟通与记录

- 一律使用中文沟通、记录和文档整理。
- 开始任何任务前，先检查 `.agent/`。
- 任务跟踪固定写入：
  - [TODO.md](.agent/TODO.md)
  - [progress.md](.agent/progress.md)
  - 涉及审查/复盘时写入 [REVIEW.md](.agent/REVIEW.md)
- `.agent/TODO.md` 与 `.agent/progress.md` 必须同步，不能一个更新、另一个滞后。
- 临时计划文档不要长期堆积在 `.agent/`；结论吸收后删除。

## 2. 工作方式

- 优先做系统化收敛，不要继续“发现一点修一点”的碎片化迭代。
- 没有明确收益时，不保留没必要的历史兼容。
- 只做当前目标直接需要的改动，不顺手扩散到周边重构。
- 先验证、再扩大范围；真实行为优先于纸面分析。

## 3. 脚本入口约定

- 项目脚本统一入口是 [scripts/runtimectl.sh](scripts/runtimectl.sh)。
- 不要恢复根目录 `build.sh`、`test_images.sh`、`run_full_pipeline.sh` 这类旧多入口脚本。
- 子命令实现放在 [scripts/commands](scripts/commands)。
- 公共能力放在 [scripts/lib](scripts/lib)。
- CI 专用适配层放在 [scripts/ci](scripts/ci)，不要把 CI 内联 shell 再堆回 workflow。

当前主要命令：
- `build`
- `test`
- `security`
- `performance`
- `optimize`
- `pipeline`
- `version`

## 4. Dockerfile 约定

- Dockerfile 风格规范以 [docs/DOCKERFILE_STYLE.md](docs/DOCKERFILE_STYLE.md) 为准。
- 不追求机械统一每一行，但以下项目尽量一致：
  - 文件头说明
  - OCI 标签
  - 环境变量顺序
  - `WORKDIR` / `USER` / `HEALTHCHECK` / `CMD`
- 需要在某个 stage 内使用的 `ARG`，必须在该 stage 重新声明，不要依赖隐含作用域。
- 不要再引入 `curl|sh`、`wget|bash` 这类远程脚本管道执行。
- 非必要不要改默认命令、用户或工作目录；这些都已经通过真实测试验证。

## 5. 文档约定

- 文档导航入口是：
  - [README.md](README.md)
  - [docs/README.md](docs/README.md)
- 根 README 负责：
  - 项目总览
  - 运行时矩阵
  - 统一命令入口
  - 文档导航
- 各 runtime README 统一使用以下结构：
  - `定位`
  - `镜像信息`
  - `构建`
  - `最小验证`
  - `常用用法`
  - `在 Gitea Actions 中使用`
  - `预装工具与环境`
  - `安全与维护`
- 只有在 runtime 确有必要时，才增加额外章节。
- 不要把同一类信息同时散落在根 README、runtime README 和额外零散文档里。

## 6. 验证顺序

### 脚本/文档改动后

至少执行：

```bash
bash tests/smoke/runtimectl_smoke.sh
bash -n scripts/runtimectl.sh scripts/commands/*.sh scripts/lib/*.sh scripts/ci/*.sh tests/smoke/runtimectl_smoke.sh
shellcheck -x scripts/runtimectl.sh scripts/commands/*.sh scripts/lib/*.sh scripts/ci/*.sh tests/smoke/runtimectl_smoke.sh
./scripts/ci/verify_workflow_config.sh
./scripts/ci/verify_dockerfile_safety.sh
```

### Dockerfile 改动后

优先做针对性真实验证：

```bash
./scripts/runtimectl.sh build --only <runtime> --platforms linux/amd64 --tag <tag>
./scripts/runtimectl.sh test --only <runtime> --tag <tag>
```

不要只停留在 dry-run 或静态检查。

## 7. 已知环境型限制

- `performance` 命令依赖宿主安装 `numfmt`。
- 非 `--analyze-only` 的 `performance` 还依赖 `bc`。
- `security` 命令在宿主没有本地扫描器时，会尝试通过 Docker 拉取 Trivy 镜像，因此受外部镜像仓库可用性影响。
- `latex` 构建和测试明显更慢，不要用普通镜像的耗时预期去判断它“卡死”。

## 8. 已知踩坑总结

- `runtime-latex`：
  - stage 内没重声明 `ARG` 会导致构建期变量为空。
  - TinyTeX 官方安装脚本实际依赖 `xz-utils`。
- `runtime-maven`：
  - 固定版本下载地址必须用可验证且稳定的官方源。
  - 非 root 用户必须有可写的 Maven 本地仓库目录。
- `runtime-claudecode`：
  - `COPY` 路径必须与统一构建上下文一致。
  - Claude 配置和 hook 模板必须安装到运行时用户 home，而不是 root home。
- `runtime-markdown`：
  - `markdownlint-cli2` 的入口脚本会依赖 `markdownlint-cli2.mjs`，不能只复制 bin 文件本身。
- `optimize`：
  - 运行后可能生成 `Dockerfile.optimized` 一类副产物，测试结束后不要把这类临时文件留在工作树里。

## 9. 提交前检查

- 确认 `.agent/TODO.md`、`.agent/progress.md`、`.agent/REVIEW.md` 与实际状态一致。
- 确认没有临时测试副产物残留。
- 确认文档导航仍然可用，根 README 不要再次变回“信息堆场”。
- 如改动 Dockerfile 或脚本，至少补相应的真实构建/真实测试证据。

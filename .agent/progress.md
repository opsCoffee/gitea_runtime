# 项目进度记录

## 时间线

### 2026-03-28 00:40
- **当前步骤**: 完成失败项修复与针对性回归
- **状态**: 已完成
- **耗时**: 35 分钟
- **关键决策 / 问题**:
  - `runtime-latex` 先修复了 `ARG` 作用域问题，随后在真实构建中继续暴露缺少 `xz-utils`，已补齐并通过真实构建与真实功能测试。
  - `runtime-maven` 已改为使用 Apache 官方 Maven Central 地址下载 `3.9.12`，并为 `appuser` 补齐 home 与 `.m2/repository`，现已通过真实构建与真实功能测试。
  - `runtime-claudecode` 已修复 `COPY` 上下文路径，并将 Claude 配置与 hook 模板安装到 `/home/nextjs`，现已通过真实构建与真实功能测试。
  - `runtime-markdown` 已补齐 `markdownlint-cli2.mjs` 运行时入口文件，现已通过真实功能测试。
  - `performance` 命令已改为对 `numfmt` / `bc` 做显式前置检查；当前本地环境缺少 `numfmt`，会明确失败而不是中途报错。
  - 修复后再次通过 smoke test、`bash -n`、`shellcheck`、workflow 配置校验和 Dockerfile 安全校验。

### 2026-03-28 00:05
- **当前步骤**: 启动失败项修复
- **状态**: 进行中
- **耗时**: 5 分钟
- **关键决策 / 问题**:
  - 本轮不再扩展验证面，直接针对上一轮本地完整测试已定位的 4 个确定性失败项做修复。
  - 修复优先级按“构建失败 > 运行失败 > 宿主依赖缺失”排序：`latex`、`maven`、`claudecode`、`markdown`、`performance`。
  - 修复完成后只重跑受影响的真实构建和真实功能测试，不做无关模块回归。

### 2026-03-28 00:02
- **当前步骤**: 完成本地完整测试并汇总结果
- **状态**: 已完成
- **耗时**: 30 分钟
- **关键决策 / 问题**:
  - 静态校验全套通过：smoke test、`bash -n`、`shellcheck`、workflow 配置校验、Dockerfile 安全校验。
  - 全量真实构建结果：`markdown/asustor/template/base` 成功；`latex/maven/claudecode` 失败。
  - 真实功能测试结果：`asustor/template/base` 成功；`markdown` 失败，原因是镜像内 `markdownlint-cli2` 启动脚本找不到 `markdownlint-cli2.mjs`。
  - 额外脚本验证结果：`optimize` 可执行；`performance --analyze-only` 因宿主缺少 `numfmt` 失败；`security --tools trivy` 因拉取 `aquasec/trivy:latest` 时 Docker Hub 鉴权 EOF 失败；`pipeline` 在复用已构建镜像时正确暴露 `markdown` 测试失败。
  - 失败根因已定位到 Dockerfile / 脚本层，而不只是外部网络噪音：`latex` 的 `TINYTEX_INSTALLER_URL` 在构建阶段为空、`maven` 下载 URL 返回 404、`claudecode` 的 `COPY runtime-claudecode/install-git-hook.sh` 与当前构建上下文不匹配。

### 2026-03-27 23:33
- **当前步骤**: 启动本地完整测试
- **状态**: 进行中
- **耗时**: 5 分钟
- **关键决策 / 问题**:
  - 用户新目标已切换为“在本地完整测试脚本与 Dockerfile”，因此本轮不再做结构改造，只做验证与记录。
  - 已确认本地 Docker Server 版本为 `28.5.2`，Buildx 版本为 `v0.29.1`，具备真实构建条件。
  - 测试顺序定为：静态校验 -> 全量真实构建 -> 全量真实功能测试 -> 视情况补充流水线级验证。

### 2026-03-27 23:55
- **当前步骤**: 完成脚本体系收敛与验证
- **状态**: 已完成
- **耗时**: 40 分钟
- **关键决策 / 问题**:
  - 确认不保留没必要的历史兼容，直接删除根目录历史脚本。
  - 统一引入 `scripts/runtimectl.sh` 作为唯一主入口，并将命令实现下沉到 `scripts/commands/*`。
  - 引入 `scripts/lib/common.sh`、`scripts/lib/runtime.sh`、`scripts/lib/report.sh` 作为公共层。
  - workflow 已切换到统一入口，`push-release` 内联 shell 已下沉到 `scripts/ci/push_release_image.sh`。
  - 已完成 smoke test、语法校验、shellcheck、workflow 配置校验和 Dockerfile 安全校验。

### 2026-03-27 23:15
- **当前步骤**: 进入脚本入口收敛实施
- **状态**: 已完成
- **耗时**: 10 分钟
- **关键决策 / 问题**:
  - 用户已明确“不必保留没必要的历史兼容”，因此实施策略从“保留根目录兼容层”调整为“统一单一主入口并同步 README / CI”。
  - 新结构目标定为：`scripts/runtimectl.sh` 作为唯一主入口，`scripts/commands/*` 承载子命令实现，`scripts/lib/*` 提供公共能力，`scripts/ci/*` 继续只做 CI 适配。
  - 仍需保留必要的命令分层，避免把全部逻辑重新塞进一个超大脚本。

### 2026-03-27 23:03
- **当前步骤**: 完成脚本体系分析与 `.agent` 清理
- **状态**: 已完成
- **耗时**: 25 分钟
- **关键决策 / 问题**:
  - 将 `.agent/` 中的 `*_plan.md` 统一视为已完成且已被核心记录吸收的临时文档，执行清理。
  - 本轮先做分析、记录收口和目录清理，再进入结构重构，避免边想边改导致再次碎片化。

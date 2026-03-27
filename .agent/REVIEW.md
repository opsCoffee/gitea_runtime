# 本地完整测试修复复盘

## 范围

本轮复盘覆盖以下内容：
1. `runtime-latex`、`runtime-maven`、`runtime-claudecode`、`runtime-markdown` 的确定性失败修复
2. `scripts/commands/performance.sh` 的宿主依赖前置检查
3. 修复后的真实构建、真实功能测试与静态回归验证

审查时间：2026-03-28 00:05 - 00:40

## 发现的问题与分级

### P1 - 已修复：`runtime-latex` 构建阶段变量作用域错误

1. 原问题：`TINYTEX_INSTALLER_URL` 和 `TINYTEX_INSTALLER_SHA256` 在 `tex-builder` stage 中没有重新声明，导致真实构建时 `wget` 实际拿到空值。
2. 处理结果：
   - 在 [runtime-latex/Dockerfile](/Users/hacker/Documents/gitea_runtime/runtime-latex/Dockerfile) 的 `tex-builder` stage 显式重新声明 `ARG`
   - 真实构建进一步暴露 TinyTeX 官方脚本依赖 `xz-utils`，已一并补齐
3. 验证结果：
   - `bash ./scripts/runtimectl.sh build --only latex --platforms linux/amd64 --tag fix3-20260328`
   - `bash ./scripts/runtimectl.sh test --only latex --tag fix3-20260328`

### P1 - 已修复：`runtime-maven` 固定下载地址失效

1. 原问题：原先的 `dlcdn.apache.org` 固定版本 URL 对 `3.9.11` 返回 404。
2. 处理结果：
   - 将 Maven 版本更新为 `3.9.12`
   - 下载地址改为 Apache 官方 Maven Central：`repo.maven.apache.org`
   - 同步更新 SHA512
   - 为非 root 用户 `appuser` 创建 home 与 `/home/appuser/.m2/repository`
3. 验证结果：
   - `bash ./scripts/runtimectl.sh build --only maven --platforms linux/amd64 --tag fix3-20260328`
   - `bash ./scripts/runtimectl.sh test --only maven --tag fix3-20260328`

### P1 - 已修复：`runtime-claudecode` 构建上下文与运行时 home 路径错误

1. 原问题：
   - `COPY runtime-claudecode/install-git-hook.sh` 与统一构建上下文不匹配
   - Claude 配置和 hook 模板被安装到 root home，而运行时用户是 `nextjs`
2. 处理结果：
   - `COPY install-git-hook.sh`
   - 在构建阶段将 `HOME` 显式设置为 `/home/nextjs`
   - 将 `.claude` 和 `.claude.json` 安装到运行时用户 home，并修正所有权
3. 验证结果：
   - `bash ./scripts/runtimectl.sh build --only claudecode --platforms linux/amd64 --tag fix3-20260328`
   - `bash ./scripts/runtimectl.sh test --only claudecode --tag fix3-20260328`

### P1 - 已修复：`runtime-markdown` 运行时入口缺文件

1. 原问题：镜像构建虽成功，但 `/usr/local/bin/markdownlint-cli2` 会相对引用缺失的 `markdownlint-cli2.mjs`。
2. 处理结果：
   - 在 [runtime-markdown/Dockerfile](/Users/hacker/Documents/gitea_runtime/runtime-markdown/Dockerfile) 中补充 `/usr/local/bin/markdownlint-cli2.mjs` 到全局模块目录的符号链接
3. 验证结果：
   - `bash ./scripts/runtimectl.sh build --only markdown --platforms linux/amd64 --tag fix3-20260328`
   - `bash ./scripts/runtimectl.sh test --only markdown --tag fix3-20260328`

### P2 - 已修复：`performance` 对宿主依赖缺少前置检查

1. 原问题：脚本真实执行时才在中途报 `numfmt: command not found`。
2. 处理结果：
   - 在 [performance.sh](/Users/hacker/Documents/gitea_runtime/scripts/commands/performance.sh) 中显式检查 `numfmt`
   - 非 `--analyze-only` 路径额外检查 `bc`
3. 验证结果：
   - `bash ./scripts/runtimectl.sh performance --only base --tag fix2-20260328 --analyze-only --report-dir .agent/local_validation_fix/performance`
   - 当前本地环境会明确输出 `错误: 缺少必需命令: numfmt`

## 修复建议或处理结果

### 修复后的真实构建结果

1. 上一轮已通过且本轮未受影响：
   - `asustor`
   - `template`
   - `base`
2. 本轮修复后已通过：
   - `markdown`
   - `latex`
   - `maven`
   - `claudecode`

### 修复后的真实功能测试结果

1. 上一轮已通过且本轮未受影响：
   - `asustor`
   - `template`
   - `base`
2. 本轮修复后已通过：
   - `markdown`
   - `latex`
   - `maven`
   - `claudecode`

### 静态回归结果

1. `bash tests/smoke/runtimectl_smoke.sh`：通过
2. `bash -n scripts/runtimectl.sh scripts/commands/*.sh scripts/lib/*.sh scripts/ci/*.sh tests/smoke/runtimectl_smoke.sh`：通过
3. `shellcheck -x scripts/runtimectl.sh scripts/commands/*.sh scripts/lib/*.sh scripts/ci/*.sh tests/smoke/runtimectl_smoke.sh`：通过
4. `./scripts/ci/verify_workflow_config.sh`：通过
5. `./scripts/ci/verify_dockerfile_safety.sh`：通过

## 验证方式与剩余风险

### 已完成验证

1. 本地真实构建：
   - `markdown` `fix3-20260328`
   - `latex` `fix3-20260328`
   - `maven` `fix3-20260328`
   - `claudecode` `fix3-20260328`
2. 本地真实功能测试：
   - `markdown` `fix3-20260328`
   - `latex` `fix3-20260328`
   - `maven` `fix3-20260328`
   - `claudecode` `fix3-20260328`
3. 镜像本地存在情况：
   - `asustor`、`template`、`base`：`localtest-20260327`
   - `markdown`、`latex`、`maven`、`claudecode`：`fix3-20260328`

### 剩余风险

1. `security` 命令仍受外部扫描器可用性和镜像仓库拉取条件影响；本地无 `trivy` 时 fallback 依赖 Docker Hub。
2. `performance` 仍依赖宿主提供 `numfmt` 与 `bc`，当前只是把失败时机前移并给出明确提示，没有消除宿主依赖本身。
3. 本轮只修复了上一轮已定位的确定性失败项，未扩展到额外的结构性重构或依赖治理。

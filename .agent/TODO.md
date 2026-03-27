# 任务标题

修复本地完整测试暴露的问题

## 背景 / 目标

上一轮本地完整测试已确认 4 个确定性问题：
1. `runtime-latex` 构建阶段 `TINYTEX_INSTALLER_URL` 丢失；
2. `runtime-maven` 固定下载地址返回 404；
3. `runtime-claudecode` 的 `COPY` 路径与构建上下文不匹配；
4. `runtime-markdown` 构建成功但 `markdownlint-cli2` 运行失败。

本轮目标是修复这些问题，并对相关命令做针对性真实回归验证。

## 待办清单

- [x] 检查 `.agent/` 当前状态并对齐任务上下文
- [x] 确认本轮修复范围只覆盖已定位的确定性失败项
- [x] 修复 `runtime-latex` 构建变量丢失问题
- [x] 修复 `runtime-maven` 下载地址失效问题
- [x] 修复 `runtime-claudecode` 构建上下文路径问题
- [x] 修复 `runtime-markdown` 运行时入口问题
- [x] 补强 `performance` 对宿主依赖的显式检查
- [x] 重新执行相关真实构建与功能测试
- [x] 同步 `.agent/TODO.md`、`.agent/progress.md`、`.agent/REVIEW.md`

## 风险 / 依赖

- `runtime-maven` 的修复依赖官方 Maven 可用下载源，需要以官方站点为准。
- 真实 Docker 构建与容器测试仍受网络、镜像源、磁盘空间和宿主 Docker 资源影响。
- 当前工作区已有大量未提交改动，本轮只修复已定位的问题，不顺手扩散改动范围。

## 验收标准

- `latex`、`maven`、`claudecode` 已通过真实本地构建。
- `markdown`、`maven`、`claudecode`、`latex` 已通过真实功能测试。
- `performance` 在缺少宿主依赖时会前置失败并给出明确错误，而不是中途报 `command not found`。
- 修复后相关构建/测试输出已证明上述确定性问题消失。

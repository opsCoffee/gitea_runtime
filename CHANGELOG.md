# 变更日志

本文档记录了项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本控制遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增
### 变更
### 修复
### 移除

## [1.0.0] - 2025-01-15

### 新增
- 版本管理系统和语义化版本控制
- 完整的自动化工具链（构建、测试、安全扫描、性能监控）
- 四个专门的运行时环境：
  - runtime-markdown: Markdown 格式化运行时
  - runtime-asustor: ASUSTOR 应用运行时  
  - runtime-template: 安全模板处理运行时
  - runtime-latex: LaTeX 文档处理运行时
- 多阶段构建优化镜像大小
- 安全最佳实践（非root用户、健康检查）
- 多工具安全扫描集成（Trivy、Grype、Docker Scout）
- 性能监控和基准测试
- 自动化优化分析和建议
- 完整的文档和使用示例

### 变更
- 统一项目结构和命名规范
- 优化 Dockerfile 风格和安全配置
- 改进构建脚本支持更多功能

### 修复
- 无

### 移除
- 无
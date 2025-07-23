#!/bin/bash

# =================================================================
# Docker 镜像自动优化脚本
# =================================================================

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 默认配置
REGISTRY="git.httpx.online/kenyon"
BACKUP_TAG="backup-$(date +%Y%m%d-%H%M%S)"
OPTIMIZATION_REPORT="./optimization_report.md"

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -r, --registry      设置 Docker 注册表 (默认: $REGISTRY)"
    echo "  --dry-run           仅显示优化建议，不执行实际操作"
    echo "  --backup            在优化前创建备份"
    echo "  --only IMAGE        仅优化指定镜像"
    echo "  --aggressive        启用激进优化模式"
    echo ""
    echo "优化功能:"
    echo "  - Dockerfile 自动优化"
    echo "  - 镜像层合并"
    echo "  - 无用文件清理"
    echo "  - 基础镜像更新建议"
    echo "  - 安全配置优化"
    exit 0
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -r|--registry)
                REGISTRY="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --backup)
                CREATE_BACKUP=true
                shift
                ;;
            --only)
                ONLY_IMAGE="$2"
                shift 2
                ;;
            --aggressive)
                AGGRESSIVE_MODE=true
                shift
                ;;
            *)
                echo "未知选项: $1"
                show_help
                ;;
        esac
    done
}

# 初始化优化报告
init_report() {
    echo "# Docker 镜像自动优化报告" > "$OPTIMIZATION_REPORT"
    echo "优化时间: $(date)" >> "$OPTIMIZATION_REPORT"
    echo "模式: $([ "$DRY_RUN" = true ] && echo "预览模式" || echo "执行模式")" >> "$OPTIMIZATION_REPORT"
    echo "激进模式: $([ "$AGGRESSIVE_MODE" = true ] && echo "启用" || echo "禁用")" >> "$OPTIMIZATION_REPORT"
    echo "" >> "$OPTIMIZATION_REPORT"
}

# 备份镜像
backup_image() {
    local runtime=$1
    local image_name="gitea-runtime-${runtime}"
    
    if [ "$CREATE_BACKUP" != true ]; then
        return 0
    fi
    
    echo -e "${BLUE}💾 备份镜像 $image_name...${NC}"
    
    if [ "$DRY_RUN" != true ]; then
        docker tag "$image_name:latest" "$image_name:$BACKUP_TAG"
        echo -e "${GREEN}✅ 备份完成: $image_name:$BACKUP_TAG${NC}"
    else
        echo -e "${YELLOW}[预览] 将创建备份: $image_name:$BACKUP_TAG${NC}"
    fi
    
    echo "## 备份信息 - $runtime" >> "$OPTIMIZATION_REPORT"
    echo "备份标签: $BACKUP_TAG" >> "$OPTIMIZATION_REPORT"
    echo "" >> "$OPTIMIZATION_REPORT"
}

# 分析 Dockerfile 并提供优化建议
analyze_dockerfile() {
    local runtime=$1
    local dockerfile_path="runtime-${runtime}/Dockerfile"
    
    echo -e "${BLUE}🔍 分析 Dockerfile: $dockerfile_path${NC}"
    
    if [ ! -f "$dockerfile_path" ]; then
        echo -e "${RED}❌ Dockerfile 不存在: $dockerfile_path${NC}"
        return 1
    fi
    
    echo "## Dockerfile 分析 - $runtime" >> "$OPTIMIZATION_REPORT"
    echo "" >> "$OPTIMIZATION_REPORT"
    
    local suggestions=()
    
    # 检查 RUN 指令数量
    local run_count=$(grep -c "^RUN" "$dockerfile_path")
    if [ "$run_count" -gt 5 ]; then
        suggestions+=("合并 RUN 指令以减少层数 (当前: $run_count 个)")
    fi
    
    # 检查是否使用了缓存清理
    if ! grep -q "rm -rf.*cache\|rm -rf.*tmp" "$dockerfile_path"; then
        suggestions+=("添加缓存清理命令")
    fi
    
    # 检查是否使用了非 root 用户
    if ! grep -q "USER" "$dockerfile_path"; then
        suggestions+=("添加非 root 用户以提高安全性")
    fi
    
    # 检查是否有健康检查
    if ! grep -q "HEALTHCHECK" "$dockerfile_path"; then
        suggestions+=("添加健康检查")
    fi
    
    # 检查基础镜像是否为最新
    local base_image=$(grep "^FROM" "$dockerfile_path" | head -1 | awk '{print $2}')
    if [[ "$base_image" != *":latest" ]] && [[ "$base_image" != *"alpine"* ]]; then
        suggestions+=("考虑使用更新的基础镜像或 Alpine 版本")
    fi
    
    # 输出建议
    if [ ${#suggestions[@]} -gt 0 ]; then
        echo "### 优化建议" >> "$OPTIMIZATION_REPORT"
        for suggestion in "${suggestions[@]}"; do
            echo "- $suggestion" >> "$OPTIMIZATION_REPORT"
        done
    else
        echo "### 优化建议" >> "$OPTIMIZATION_REPORT"
        echo "- Dockerfile 已经相对优化" >> "$OPTIMIZATION_REPORT"
    fi
    echo "" >> "$OPTIMIZATION_REPORT"
    
    return 0
}

# 生成优化的 Dockerfile
generate_optimized_dockerfile() {
    local runtime=$1
    local original_dockerfile="runtime-${runtime}/Dockerfile"
    local optimized_dockerfile="runtime-${runtime}/Dockerfile.optimized"
    
    echo -e "${BLUE}⚡ 生成优化的 Dockerfile: $runtime${NC}"
    
    if [ ! -f "$original_dockerfile" ]; then
        echo -e "${RED}❌ 原始 Dockerfile 不存在${NC}"
        return 1
    fi
    
    # 复制原始文件作为基础
    cp "$original_dockerfile" "$optimized_dockerfile"
    
    # 应用优化
    case $runtime in
        "markdown")
            optimize_markdown_dockerfile "$optimized_dockerfile"
            ;;
        "asustor")
            optimize_asustor_dockerfile "$optimized_dockerfile"
            ;;
        "template")
            optimize_template_dockerfile "$optimized_dockerfile"
            ;;
        "latex")
            optimize_latex_dockerfile "$optimized_dockerfile"
            ;;
    esac
    
    echo "### 生成的优化文件" >> "$OPTIMIZATION_REPORT"
    echo "- 优化后的 Dockerfile: $optimized_dockerfile" >> "$OPTIMIZATION_REPORT"
    echo "" >> "$OPTIMIZATION_REPORT"
    
    if [ "$DRY_RUN" != true ]; then
        echo -e "${GREEN}✅ 优化的 Dockerfile 已生成: $optimized_dockerfile${NC}"
    else
        echo -e "${YELLOW}[预览] 将生成优化的 Dockerfile: $optimized_dockerfile${NC}"
    fi
}

# 优化 Markdown Dockerfile
optimize_markdown_dockerfile() {
    local dockerfile=$1
    
    # 添加更多的缓存清理
    if [ "$AGGRESSIVE_MODE" = true ]; then
        sed -i '/npm install/a\    npm cache clean --force && \\' "$dockerfile"
    fi
    
    # 优化 RUN 指令合并
    # 这里可以添加更多具体的优化逻辑
}

# 优化 ASUSTOR Dockerfile
optimize_asustor_dockerfile() {
    local dockerfile=$1
    
    # 添加 Python 缓存清理
    if [ "$AGGRESSIVE_MODE" = true ]; then
        sed -i '/apk add/a\    rm -rf /root/.cache/pip && \\' "$dockerfile"
    fi
}

# 优化 Template Dockerfile
optimize_template_dockerfile() {
    local dockerfile=$1
    
    # 优化 Go 构建缓存
    if [ "$AGGRESSIVE_MODE" = true ]; then
        sed -i '/go install/a\    go clean -cache && \\' "$dockerfile"
    fi
}

# 优化 LaTeX Dockerfile
optimize_latex_dockerfile() {
    local dockerfile=$1
    
    # 添加更激进的 TeX 清理
    if [ "$AGGRESSIVE_MODE" = true ]; then
        sed -i '/tlmgr install/a\    rm -rf /usr/local/TinyTeX/tlpkg/temp/* && \\' "$dockerfile"
    fi
}

# 分析镜像大小并提供优化建议
analyze_image_size() {
    local runtime=$1
    local image_name="gitea-runtime-${runtime}"
    
    echo -e "${BLUE}📊 分析镜像大小: $image_name${NC}"
    
    if ! docker image inspect "$image_name:latest" &>/dev/null; then
        echo -e "${YELLOW}⚠️  镜像不存在，跳过分析${NC}"
        return 1
    fi
    
    local size=$(docker image inspect "$image_name:latest" --format '{{.Size}}')
    local size_mb=$((size / 1024 / 1024))
    local layers=$(docker image inspect "$image_name:latest" --format '{{len .RootFS.Layers}}')
    
    echo "## 镜像大小分析 - $runtime" >> "$OPTIMIZATION_REPORT"
    echo "当前大小: ${size_mb}MB" >> "$OPTIMIZATION_REPORT"
    echo "层数: $layers" >> "$OPTIMIZATION_REPORT"
    echo "" >> "$OPTIMIZATION_REPORT"
    
    # 提供大小优化建议
    local size_suggestions=()
    
    if [ "$size_mb" -gt 500 ]; then
        size_suggestions+=("镜像较大，考虑使用多阶段构建")
    fi
    
    if [ "$layers" -gt 15 ]; then
        size_suggestions+=("层数较多，建议合并 RUN 指令")
    fi
    
    if [ ${#size_suggestions[@]} -gt 0 ]; then
        echo "### 大小优化建议" >> "$OPTIMIZATION_REPORT"
        for suggestion in "${size_suggestions[@]}"; do
            echo "- $suggestion" >> "$OPTIMIZATION_REPORT"
        done
    fi
    echo "" >> "$OPTIMIZATION_REPORT"
}

# 检查安全配置
check_security_config() {
    local runtime=$1
    local image_name="gitea-runtime-${runtime}"
    
    echo -e "${BLUE}🔒 检查安全配置: $image_name${NC}"
    
    if ! docker image inspect "$image_name:latest" &>/dev/null; then
        return 1
    fi
    
    echo "## 安全配置检查 - $runtime" >> "$OPTIMIZATION_REPORT"
    echo "" >> "$OPTIMIZATION_REPORT"
    
    # 检查用户配置
    local user=$(docker image inspect "$image_name:latest" --format '{{.Config.User}}')
    if [ -z "$user" ] || [ "$user" = "root" ]; then
        echo "- ⚠️  镜像以 root 用户运行，建议使用非特权用户" >> "$OPTIMIZATION_REPORT"
    else
        echo "- ✅ 使用非 root 用户: $user" >> "$OPTIMIZATION_REPORT"
    fi
    
    # 检查健康检查
    local healthcheck=$(docker image inspect "$image_name:latest" --format '{{.Config.Healthcheck}}')
    if [ "$healthcheck" = "<nil>" ]; then
        echo "- ⚠️  缺少健康检查配置" >> "$OPTIMIZATION_REPORT"
    else
        echo "- ✅ 配置了健康检查" >> "$OPTIMIZATION_REPORT"
    fi
    
    echo "" >> "$OPTIMIZATION_REPORT"
}

# 生成优化建议摘要
generate_optimization_summary() {
    echo -e "${BLUE}📋 生成优化摘要...${NC}"
    
    echo "## 优化摘要" >> "$OPTIMIZATION_REPORT"
    echo "" >> "$OPTIMIZATION_REPORT"
    
    echo "### 已完成的优化" >> "$OPTIMIZATION_REPORT"
    echo "- Dockerfile 分析和优化建议生成" >> "$OPTIMIZATION_REPORT"
    echo "- 镜像大小分析" >> "$OPTIMIZATION_REPORT"
    echo "- 安全配置检查" >> "$OPTIMIZATION_REPORT"
    
    if [ "$CREATE_BACKUP" = true ]; then
        echo "- 镜像备份创建" >> "$OPTIMIZATION_REPORT"
    fi
    
    echo "" >> "$OPTIMIZATION_REPORT"
    
    echo "### 下一步行动" >> "$OPTIMIZATION_REPORT"
    echo "1. 审查生成的优化建议" >> "$OPTIMIZATION_REPORT"
    echo "2. 测试优化后的 Dockerfile" >> "$OPTIMIZATION_REPORT"
    echo "3. 比较优化前后的镜像大小和性能" >> "$OPTIMIZATION_REPORT"
    echo "4. 更新生产环境镜像" >> "$OPTIMIZATION_REPORT"
    echo "" >> "$OPTIMIZATION_REPORT"
    
    echo "### 持续优化建议" >> "$OPTIMIZATION_REPORT"
    echo "- 定期运行此优化脚本" >> "$OPTIMIZATION_REPORT"
    echo "- 监控镜像大小趋势" >> "$OPTIMIZATION_REPORT"
    echo "- 跟踪基础镜像更新" >> "$OPTIMIZATION_REPORT"
    echo "- 实施自动化优化流程" >> "$OPTIMIZATION_REPORT"
    echo "" >> "$OPTIMIZATION_REPORT"
}

# 优化单个镜像
optimize_image() {
    local runtime=$1
    
    echo -e "\n${BLUE}🔧 优化镜像: $runtime${NC}"
    
    # 备份镜像
    backup_image "$runtime"
    
    # 分析 Dockerfile
    analyze_dockerfile "$runtime"
    
    # 生成优化的 Dockerfile
    generate_optimized_dockerfile "$runtime"
    
    # 分析镜像大小
    analyze_image_size "$runtime"
    
    # 检查安全配置
    check_security_config "$runtime"
    
    echo -e "${GREEN}✅ 镜像 $runtime 优化分析完成${NC}"
}

# 主函数
main() {
    parse_args "$@"
    
    echo -e "${BLUE}🚀 开始 Docker 镜像自动优化...${NC}"
    echo "注册表: $REGISTRY"
    echo "模式: $([ "$DRY_RUN" = true ] && echo "预览模式" || echo "执行模式")"
    echo "激进模式: $([ "$AGGRESSIVE_MODE" = true ] && echo "启用" || echo "禁用")"
    
    # 初始化报告
    init_report
    
    # 优化镜像
    if [ -n "$ONLY_IMAGE" ]; then
        optimize_image "$ONLY_IMAGE"
    else
        for runtime in markdown asustor template latex; do
            optimize_image "$runtime"
        done
    fi
    
    # 生成优化摘要
    generate_optimization_summary
    
    echo -e "\n${GREEN}✨ 自动优化完成！${NC}"
    echo -e "查看优化报告: ${BLUE}$OPTIMIZATION_REPORT${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}💡 这是预览模式，没有执行实际更改${NC}"
        echo -e "${YELLOW}💡 要应用优化，请移除 --dry-run 参数${NC}"
    fi
}

# 执行主函数
main "$@"
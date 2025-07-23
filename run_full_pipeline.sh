#!/bin/bash

# =================================================================
# Docker 镜像完整流水线脚本
# =================================================================

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 默认配置
REGISTRY="git.httpx.online/kenyon"
REPORT_DIR="./pipeline_reports"
SKIP_BUILD=false
SKIP_TEST=false
SKIP_SECURITY=false
SKIP_PERFORMANCE=false
SKIP_OPTIMIZATION=false

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -r, --registry      设置 Docker 注册表 (默认: $REGISTRY)"
    echo "  -d, --report-dir    设置报告输出目录 (默认: $REPORT_DIR)"
    echo "  --only IMAGE        仅处理指定镜像"
    echo "  --skip-build        跳过构建步骤"
    echo "  --skip-test         跳过测试步骤"
    echo "  --skip-security     跳过安全扫描"
    echo "  --skip-performance  跳过性能监控"
    echo "  --skip-optimization 跳过优化分析"
    echo "  --quick             快速模式（跳过性能和优化）"
    echo ""
    echo "流水线步骤:"
    echo "  1. 构建镜像"
    echo "  2. 运行测试"
    echo "  3. 安全扫描"
    echo "  4. 性能监控"
    echo "  5. 优化分析"
    echo "  6. 生成综合报告"
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
            -d|--report-dir)
                REPORT_DIR="$2"
                shift 2
                ;;
            --only)
                ONLY_IMAGE="$2"
                shift 2
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-test)
                SKIP_TEST=true
                shift
                ;;
            --skip-security)
                SKIP_SECURITY=true
                shift
                ;;
            --skip-performance)
                SKIP_PERFORMANCE=true
                shift
                ;;
            --skip-optimization)
                SKIP_OPTIMIZATION=true
                shift
                ;;
            --quick)
                SKIP_PERFORMANCE=true
                SKIP_OPTIMIZATION=true
                shift
                ;;
            *)
                echo "未知选项: $1"
                show_help
                ;;
        esac
    done
}

# 初始化流水线
init_pipeline() {
    echo -e "${BLUE}🚀 初始化 Docker 镜像完整流水线...${NC}"
    echo "开始时间: $(date)"
    echo "注册表: $REGISTRY"
    echo "报告目录: $REPORT_DIR"
    echo "处理镜像: $([ -n "$ONLY_IMAGE" ] && echo "$ONLY_IMAGE" || echo "全部")"
    echo ""
    
    # 创建报告目录
    mkdir -p "$REPORT_DIR"
    
    # 初始化流水线报告
    cat > "$REPORT_DIR/pipeline_summary.md" << EOF
# Docker 镜像流水线执行报告

**执行时间**: $(date)
**注册表**: $REGISTRY
**处理镜像**: $([ -n "$ONLY_IMAGE" ] && echo "$ONLY_IMAGE" || echo "全部")

## 流水线步骤

EOF
}

# 执行构建步骤
run_build_step() {
    if [ "$SKIP_BUILD" = true ]; then
        echo -e "${YELLOW}⏭️  跳过构建步骤${NC}"
        echo "- ⏭️ 构建步骤: 已跳过" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    fi
    
    echo -e "\n${BLUE}🔨 步骤 1: 构建镜像${NC}"
    
    local build_args="--registry $REGISTRY"
    if [ -n "$ONLY_IMAGE" ]; then
        build_args="$build_args --only $ONLY_IMAGE"
    fi
    
    if chmod +x ./build.sh && ./build.sh $build_args; then
        echo -e "${GREEN}✅ 构建步骤完成${NC}"
        echo "- ✅ 构建步骤: 成功" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    else
        echo -e "${RED}❌ 构建步骤失败${NC}"
        echo "- ❌ 构建步骤: 失败" >> "$REPORT_DIR/pipeline_summary.md"
        return 1
    fi
}

# 执行测试步骤
run_test_step() {
    if [ "$SKIP_TEST" = true ]; then
        echo -e "${YELLOW}⏭️  跳过测试步骤${NC}"
        echo "- ⏭️ 测试步骤: 已跳过" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    fi
    
    echo -e "\n${BLUE}🧪 步骤 2: 运行测试${NC}"
    
    local test_args="--registry $REGISTRY"
    if [ -n "$ONLY_IMAGE" ]; then
        test_args="$ONLY_IMAGE $test_args"
    fi
    
    if chmod +x ./test_images.sh && ./test_images.sh $test_args; then
        echo -e "${GREEN}✅ 测试步骤完成${NC}"
        echo "- ✅ 测试步骤: 成功" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    else
        echo -e "${RED}❌ 测试步骤失败${NC}"
        echo "- ❌ 测试步骤: 失败" >> "$REPORT_DIR/pipeline_summary.md"
        return 1
    fi
}

# 执行安全扫描步骤
run_security_step() {
    if [ "$SKIP_SECURITY" = true ]; then
        echo -e "${YELLOW}⏭️  跳过安全扫描步骤${NC}"
        echo "- ⏭️ 安全扫描: 已跳过" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    fi
    
    echo -e "\n${BLUE}🔒 步骤 3: 安全扫描${NC}"
    
    local security_args="--registry $REGISTRY --report-dir $REPORT_DIR/security"
    if [ -n "$ONLY_IMAGE" ]; then
        security_args="$security_args --only $ONLY_IMAGE"
    fi
    
    if chmod +x ./security_scanner.sh && ./security_scanner.sh $security_args; then
        echo -e "${GREEN}✅ 安全扫描完成${NC}"
        echo "- ✅ 安全扫描: 完成" >> "$REPORT_DIR/pipeline_summary.md"
        
        # 复制安全报告摘要
        if [ -f "$REPORT_DIR/security/security_summary.md" ]; then
            echo "" >> "$REPORT_DIR/pipeline_summary.md"
            echo "### 安全扫描摘要" >> "$REPORT_DIR/pipeline_summary.md"
            tail -n +3 "$REPORT_DIR/security/security_summary.md" >> "$REPORT_DIR/pipeline_summary.md"
        fi
        
        return 0
    else
        echo -e "${YELLOW}⚠️  安全扫描部分失败，继续执行${NC}"
        echo "- ⚠️ 安全扫描: 部分失败" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    fi
}

# 执行性能监控步骤
run_performance_step() {
    if [ "$SKIP_PERFORMANCE" = true ]; then
        echo -e "${YELLOW}⏭️  跳过性能监控步骤${NC}"
        echo "- ⏭️ 性能监控: 已跳过" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    fi
    
    echo -e "\n${BLUE}📊 步骤 4: 性能监控${NC}"
    
    local perf_args="--registry $REGISTRY --report-dir $REPORT_DIR/performance"
    
    if chmod +x ./performance_monitor.sh && ./performance_monitor.sh $perf_args; then
        echo -e "${GREEN}✅ 性能监控完成${NC}"
        echo "- ✅ 性能监控: 完成" >> "$REPORT_DIR/pipeline_summary.md"
        
        # 复制性能报告摘要
        if [ -f "$REPORT_DIR/performance/performance_summary.md" ]; then
            echo "" >> "$REPORT_DIR/pipeline_summary.md"
            echo "### 性能监控摘要" >> "$REPORT_DIR/pipeline_summary.md"
            tail -n +3 "$REPORT_DIR/performance/performance_summary.md" >> "$REPORT_DIR/pipeline_summary.md"
        fi
        
        return 0
    else
        echo -e "${YELLOW}⚠️  性能监控部分失败，继续执行${NC}"
        echo "- ⚠️ 性能监控: 部分失败" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    fi
}

# 执行优化分析步骤
run_optimization_step() {
    if [ "$SKIP_OPTIMIZATION" = true ]; then
        echo -e "${YELLOW}⏭️  跳过优化分析步骤${NC}"
        echo "- ⏭️ 优化分析: 已跳过" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    fi
    
    echo -e "\n${BLUE}⚡ 步骤 5: 优化分析${NC}"
    
    local opt_args="--registry $REGISTRY --dry-run"
    if [ -n "$ONLY_IMAGE" ]; then
        opt_args="$opt_args --only $ONLY_IMAGE"
    fi
    
    if chmod +x ./auto_optimizer.sh && ./auto_optimizer.sh $opt_args; then
        echo -e "${GREEN}✅ 优化分析完成${NC}"
        echo "- ✅ 优化分析: 完成" >> "$REPORT_DIR/pipeline_summary.md"
        
        # 移动优化报告到流水线报告目录
        if [ -f "./optimization_report.md" ]; then
            mv "./optimization_report.md" "$REPORT_DIR/optimization_report.md"
        fi
        
        return 0
    else
        echo -e "${YELLOW}⚠️  优化分析部分失败，继续执行${NC}"
        echo "- ⚠️ 优化分析: 部分失败" >> "$REPORT_DIR/pipeline_summary.md"
        return 0
    fi
}

# 生成综合报告
generate_comprehensive_report() {
    echo -e "\n${BLUE}📋 步骤 6: 生成综合报告${NC}"
    
    local final_report="$REPORT_DIR/comprehensive_report.md"
    
    cat > "$final_report" << EOF
# Docker 镜像流水线综合报告

**生成时间**: $(date)
**执行耗时**: $(($(date +%s) - START_TIME)) 秒
**注册表**: $REGISTRY
**处理镜像**: $([ -n "$ONLY_IMAGE" ] && echo "$ONLY_IMAGE" || echo "全部")

## 执行摘要

EOF
    
    # 添加流水线摘要
    if [ -f "$REPORT_DIR/pipeline_summary.md" ]; then
        tail -n +5 "$REPORT_DIR/pipeline_summary.md" >> "$final_report"
    fi
    
    echo "" >> "$final_report"
    echo "## 详细报告链接" >> "$final_report"
    echo "" >> "$final_report"
    
    # 添加各个报告的链接
    if [ -f "$REPORT_DIR/security/security_summary.md" ]; then
        echo "- [安全扫描详细报告](security/security_summary.md)" >> "$final_report"
    fi
    
    if [ -f "$REPORT_DIR/performance/performance_summary.md" ]; then
        echo "- [性能监控详细报告](performance/performance_summary.md)" >> "$final_report"
    fi
    
    if [ -f "$REPORT_DIR/optimization_report.md" ]; then
        echo "- [优化分析详细报告](optimization_report.md)" >> "$final_report"
    fi
    
    echo "" >> "$final_report"
    echo "## 建议行动项" >> "$final_report"
    echo "" >> "$final_report"
    echo "### 立即行动" >> "$final_report"
    echo "1. 审查安全扫描发现的严重和高危漏洞" >> "$final_report"
    echo "2. 检查测试失败的项目并修复" >> "$final_report"
    echo "3. 考虑应用优化建议以减小镜像大小" >> "$final_report"
    echo "" >> "$final_report"
    
    echo "### 持续改进" >> "$final_report"
    echo "1. 建立定期执行此流水线的计划" >> "$final_report"
    echo "2. 监控镜像性能和安全趋势" >> "$final_report"
    echo "3. 自动化关键优化措施" >> "$final_report"
    echo "4. 更新基础镜像和依赖" >> "$final_report"
    echo "" >> "$final_report"
    
    echo -e "${GREEN}✅ 综合报告生成完成: $final_report${NC}"
}

# 清理临时文件
cleanup() {
    echo -e "\n${BLUE}🧹 清理临时文件...${NC}"
    
    # 清理 Docker 悬空镜像
    docker images --filter "dangling=true" --format '{{.ID}}' | xargs -r docker rmi 2>/dev/null || true
    
    # 清理构建缓存
    docker builder prune --force --filter until=24h 2>/dev/null || true
    
    echo -e "${GREEN}✅ 清理完成${NC}"
}

# 主函数
main() {
    START_TIME=$(date +%s)
    
    parse_args "$@"
    init_pipeline
    
    local exit_code=0
    
    # 执行流水线步骤
    run_build_step || exit_code=1
    run_test_step || exit_code=1
    run_security_step
    run_performance_step
    run_optimization_step
    
    # 生成综合报告
    generate_comprehensive_report
    
    # 清理
    cleanup
    
    # 显示结果
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    echo -e "\n${BLUE}📊 流水线执行完成${NC}"
    echo "总耗时: ${duration} 秒"
    echo -e "综合报告: ${GREEN}$REPORT_DIR/comprehensive_report.md${NC}"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✨ 流水线执行成功！${NC}"
    else
        echo -e "${YELLOW}⚠️  流水线执行完成，但有部分步骤失败${NC}"
    fi
    
    return $exit_code
}

# 执行主函数
main "$@"
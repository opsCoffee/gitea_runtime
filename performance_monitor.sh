#!/bin/bash

# =================================================================
# Docker 镜像性能监控和优化脚本
# =================================================================

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 默认配置
REGISTRY="git.httpx.online/kenyon"
REPORT_DIR="./performance_reports"
BENCHMARK_ITERATIONS=3

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -r, --registry      设置 Docker 注册表 (默认: $REGISTRY)"
    echo "  -d, --report-dir    设置报告输出目录 (默认: $REPORT_DIR)"
    echo "  -i, --iterations    设置基准测试迭代次数 (默认: $BENCHMARK_ITERATIONS)"
    echo "  --analyze-only      仅分析现有镜像，不运行基准测试"
    echo ""
    echo "功能:"
    echo "  - 镜像大小分析"
    echo "  - 启动时间基准测试"
    echo "  - 资源使用监控"
    echo "  - 层级分析"
    echo "  - 优化建议生成"
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
            -i|--iterations)
                BENCHMARK_ITERATIONS="$2"
                shift 2
                ;;
            --analyze-only)
                ANALYZE_ONLY=true
                shift
                ;;
            *)
                echo "未知选项: $1"
                show_help
                ;;
        esac
    done
}

# 创建报告目录
setup_report_dir() {
    mkdir -p "$REPORT_DIR"
    echo -e "${BLUE}📁 报告将保存到: $REPORT_DIR${NC}"
}

# 分析镜像大小
analyze_image_sizes() {
    local report_file="$REPORT_DIR/image_sizes.md"
    
    echo -e "\n${BLUE}📊 分析镜像大小...${NC}"
    echo "# Docker 镜像大小分析报告" > "$report_file"
    echo "生成时间: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "| 镜像名称 | 大小 | 压缩大小 | 层数 | 优化建议 |" >> "$report_file"
    echo "|----------|------|----------|------|----------|" >> "$report_file"
    
    for runtime in markdown asustor template latex; do
        local image_name="gitea-runtime-${runtime}"
        local full_name="${REGISTRY}/${image_name}:latest"
        
        if docker image inspect "$image_name:latest" &>/dev/null; then
            local size=$(docker image inspect "$image_name:latest" --format '{{.Size}}' | numfmt --to=iec)
            local layers=$(docker image inspect "$image_name:latest" --format '{{len .RootFS.Layers}}')
            local compressed_size=$(docker image inspect "$image_name:latest" --format '{{.VirtualSize}}' | numfmt --to=iec)
            
            # 生成优化建议
            local suggestions=""
            if [ "$layers" -gt 10 ]; then
                suggestions="减少层数"
            fi
            if [[ "$size" == *G* ]]; then
                suggestions="${suggestions:+$suggestions, }考虑多阶段构建"
            fi
            if [ -z "$suggestions" ]; then
                suggestions="已优化"
            fi
            
            echo "| $image_name | $size | $compressed_size | $layers | $suggestions |" >> "$report_file"
        else
            echo "| $image_name | N/A | N/A | N/A | 镜像不存在 |" >> "$report_file"
        fi
    done
    
    echo -e "${GREEN}✅ 镜像大小分析完成: $report_file${NC}"
}

# 基准测试启动时间
benchmark_startup_time() {
    if [ "$ANALYZE_ONLY" = true ]; then
        return 0
    fi
    
    local report_file="$REPORT_DIR/startup_benchmark.md"
    
    echo -e "\n${BLUE}⏱️  基准测试启动时间...${NC}"
    echo "# Docker 镜像启动时间基准测试" > "$report_file"
    echo "生成时间: $(date)" >> "$report_file"
    echo "测试迭代次数: $BENCHMARK_ITERATIONS" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "| 镜像名称 | 平均启动时间(ms) | 最小时间(ms) | 最大时间(ms) | 标准差 |" >> "$report_file"
    echo "|----------|------------------|--------------|--------------|--------|" >> "$report_file"
    
    for runtime in markdown asustor template latex; do
        local image_name="gitea-runtime-${runtime}"
        
        if docker image inspect "$image_name:latest" &>/dev/null; then
            echo -e "${YELLOW}测试 $image_name 启动时间...${NC}"
            
            local times=()
            for i in $(seq 1 $BENCHMARK_ITERATIONS); do
                local start_time=$(date +%s%3N)
                docker run --rm "$image_name:latest" echo "test" > /dev/null 2>&1
                local end_time=$(date +%s%3N)
                local duration=$((end_time - start_time))
                times+=($duration)
            done
            
            # 计算统计数据
            local sum=0
            local min=${times[0]}
            local max=${times[0]}
            
            for time in "${times[@]}"; do
                sum=$((sum + time))
                if [ $time -lt $min ]; then min=$time; fi
                if [ $time -gt $max ]; then max=$time; fi
            done
            
            local avg=$((sum / BENCHMARK_ITERATIONS))
            
            # 计算标准差
            local variance_sum=0
            for time in "${times[@]}"; do
                local diff=$((time - avg))
                variance_sum=$((variance_sum + diff * diff))
            done
            local std_dev=$(echo "scale=2; sqrt($variance_sum / $BENCHMARK_ITERATIONS)" | bc -l)
            
            echo "| $image_name | $avg | $min | $max | $std_dev |" >> "$report_file"
        else
            echo "| $image_name | N/A | N/A | N/A | N/A |" >> "$report_file"
        fi
    done
    
    echo -e "${GREEN}✅ 启动时间基准测试完成: $report_file${NC}"
}

# 分析镜像层级结构
analyze_image_layers() {
    local report_file="$REPORT_DIR/layer_analysis.md"
    
    echo -e "\n${BLUE}🔍 分析镜像层级结构...${NC}"
    echo "# Docker 镜像层级分析报告" > "$report_file"
    echo "生成时间: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    for runtime in markdown asustor template latex; do
        local image_name="gitea-runtime-${runtime}"
        
        if docker image inspect "$image_name:latest" &>/dev/null; then
            echo "## $image_name" >> "$report_file"
            echo "" >> "$report_file"
            
            # 获取层级信息
            echo "### 层级详情" >> "$report_file"
            echo '```' >> "$report_file"
            docker history "$image_name:latest" --no-trunc >> "$report_file"
            echo '```' >> "$report_file"
            echo "" >> "$report_file"
            
            # 分析大文件
            echo "### 大文件分析" >> "$report_file"
            echo '```' >> "$report_file"
            docker run --rm "$image_name:latest" find / -type f -size +10M 2>/dev/null | head -10 >> "$report_file" || true
            echo '```' >> "$report_file"
            echo "" >> "$report_file"
        fi
    done
    
    echo -e "${GREEN}✅ 层级分析完成: $report_file${NC}"
}

# 生成优化建议
generate_optimization_suggestions() {
    local report_file="$REPORT_DIR/optimization_suggestions.md"
    
    echo -e "\n${BLUE}💡 生成优化建议...${NC}"
    echo "# Docker 镜像优化建议" > "$report_file"
    echo "生成时间: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "## 通用优化建议" >> "$report_file"
    echo "" >> "$report_file"
    echo "1. **减少镜像层数**" >> "$report_file"
    echo "   - 合并 RUN 指令" >> "$report_file"
    echo "   - 使用多阶段构建" >> "$report_file"
    echo "   - 清理包管理器缓存" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "2. **优化基础镜像选择**" >> "$report_file"
    echo "   - 使用 Alpine Linux 减小体积" >> "$report_file"
    echo "   - 选择合适的基础镜像版本" >> "$report_file"
    echo "   - 避免不必要的工具安装" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "3. **安全性优化**" >> "$report_file"
    echo "   - 使用非 root 用户运行" >> "$report_file"
    echo "   - 定期更新基础镜像" >> "$report_file"
    echo "   - 移除不必要的包和文件" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "4. **构建效率优化**" >> "$report_file"
    echo "   - 使用 BuildKit 缓存" >> "$report_file"
    echo "   - 优化 .dockerignore 文件" >> "$report_file"
    echo "   - 并行构建多个镜像" >> "$report_file"
    echo "" >> "$report_file"
    
    # 针对每个镜像的具体建议
    for runtime in markdown asustor template latex; do
        local image_name="gitea-runtime-${runtime}"
        
        if docker image inspect "$image_name:latest" &>/dev/null; then
            echo "## $image_name 特定建议" >> "$report_file"
            echo "" >> "$report_file"
            
            case $runtime in
                "markdown")
                    echo "- 考虑使用更轻量的 Markdown 处理工具" >> "$report_file"
                    echo "- 优化 Node.js 模块安装" >> "$report_file"
                    ;;
                "asustor")
                    echo "- 精简 Python 包安装" >> "$report_file"
                    echo "- 考虑使用 Python slim 镜像" >> "$report_file"
                    ;;
                "template")
                    echo "- 优化 Go 二进制文件大小" >> "$report_file"
                    echo "- 考虑静态链接减少依赖" >> "$report_file"
                    ;;
                "latex")
                    echo "- 进一步精简 TeX 发行版" >> "$report_file"
                    echo "- 移除不必要的字体和文档" >> "$report_file"
                    ;;
            esac
            echo "" >> "$report_file"
        fi
    done
    
    echo -e "${GREEN}✅ 优化建议生成完成: $report_file${NC}"
}

# 生成汇总报告
generate_summary_report() {
    local summary_file="$REPORT_DIR/performance_summary.md"
    
    echo -e "\n${BLUE}📋 生成汇总报告...${NC}"
    echo "# Docker 镜像性能监控汇总报告" > "$summary_file"
    echo "生成时间: $(date)" >> "$summary_file"
    echo "" >> "$summary_file"
    
    echo "## 报告文件列表" >> "$summary_file"
    echo "" >> "$summary_file"
    for report in "$REPORT_DIR"/*.md; do
        if [ -f "$report" ] && [ "$(basename "$report")" != "performance_summary.md" ]; then
            echo "- [$(basename "$report" .md)]($(basename "$report"))" >> "$summary_file"
        fi
    done
    echo "" >> "$summary_file"
    
    echo "## 快速统计" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "- 分析的镜像数量: 4" >> "$summary_file"
    echo "- 报告生成时间: $(date)" >> "$summary_file"
    echo "- 基准测试迭代次数: $BENCHMARK_ITERATIONS" >> "$summary_file"
    echo "" >> "$summary_file"
    
    echo -e "${GREEN}✅ 汇总报告生成完成: $summary_file${NC}"
}

# 主函数
main() {
    parse_args "$@"
    
    echo -e "${BLUE}🚀 开始 Docker 镜像性能监控...${NC}"
    echo "注册表: $REGISTRY"
    echo "报告目录: $REPORT_DIR"
    echo "基准测试迭代次数: $BENCHMARK_ITERATIONS"
    
    setup_report_dir
    analyze_image_sizes
    benchmark_startup_time
    analyze_image_layers
    generate_optimization_suggestions
    generate_summary_report
    
    echo -e "\n${GREEN}✨ 性能监控完成！${NC}"
    echo -e "查看汇总报告: ${BLUE}$REPORT_DIR/performance_summary.md${NC}"
}

# 执行主函数
main "$@"
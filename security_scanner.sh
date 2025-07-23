#!/bin/bash

# =================================================================
# Docker 镜像安全扫描增强脚本
# =================================================================

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 默认配置
REGISTRY="git.httpx.online/kenyon"
REPORT_DIR="./security_reports"
SCAN_TOOLS=("trivy" "grype" "docker-scout")
SEVERITY_LEVELS="CRITICAL,HIGH,MEDIUM"

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -r, --registry      设置 Docker 注册表 (默认: $REGISTRY)"
    echo "  -d, --report-dir    设置报告输出目录 (默认: $REPORT_DIR)"
    echo "  -s, --severity      设置严重性级别 (默认: $SEVERITY_LEVELS)"
    echo "  -t, --tools         指定扫描工具 (trivy,grype,docker-scout)"
    echo "  --only IMAGE        仅扫描指定镜像"
    echo "  --baseline          生成基线报告"
    echo "  --compare           与基线报告比较"
    echo ""
    echo "功能:"
    echo "  - 多工具安全扫描"
    echo "  - 漏洞趋势分析"
    echo "  - 合规性检查"
    echo "  - 基线比较"
    echo "  - 修复建议生成"
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
            -s|--severity)
                SEVERITY_LEVELS="$2"
                shift 2
                ;;
            -t|--tools)
                IFS=',' read -ra SCAN_TOOLS <<< "$2"
                shift 2
                ;;
            --only)
                ONLY_IMAGE="$2"
                shift 2
                ;;
            --baseline)
                GENERATE_BASELINE=true
                shift
                ;;
            --compare)
                COMPARE_BASELINE=true
                shift
                ;;
            *)
                echo "未知选项: $1"
                show_help
                ;;
        esac
    done
}

# 检查扫描工具是否可用
check_scan_tools() {
    echo -e "${BLUE}🔧 检查扫描工具可用性...${NC}"
    
    local available_tools=()
    
    for tool in "${SCAN_TOOLS[@]}"; do
        case $tool in
            "trivy")
                if command -v trivy &> /dev/null || docker image inspect aquasec/trivy:latest &> /dev/null; then
                    available_tools+=("trivy")
                    echo -e "${GREEN}✅ Trivy 可用${NC}"
                else
                    echo -e "${YELLOW}⚠️  Trivy 不可用，将使用 Docker 运行${NC}"
                    available_tools+=("trivy")
                fi
                ;;
            "grype")
                if command -v grype &> /dev/null; then
                    available_tools+=("grype")
                    echo -e "${GREEN}✅ Grype 可用${NC}"
                else
                    echo -e "${YELLOW}⚠️  Grype 不可用，跳过${NC}"
                fi
                ;;
            "docker-scout")
                if docker scout version &> /dev/null; then
                    available_tools+=("docker-scout")
                    echo -e "${GREEN}✅ Docker Scout 可用${NC}"
                else
                    echo -e "${YELLOW}⚠️  Docker Scout 不可用，跳过${NC}"
                fi
                ;;
        esac
    done
    
    SCAN_TOOLS=("${available_tools[@]}")
    
    if [ ${#SCAN_TOOLS[@]} -eq 0 ]; then
        echo -e "${RED}❌ 没有可用的扫描工具${NC}"
        exit 1
    fi
}

# 使用 Trivy 扫描
scan_with_trivy() {
    local image_name=$1
    local output_dir=$2
    
    echo -e "${BLUE}🔍 使用 Trivy 扫描 $image_name...${NC}"
    
    # JSON 格式报告
    if command -v trivy &> /dev/null; then
        trivy image --format json --severity "$SEVERITY_LEVELS" \
            --output "$output_dir/trivy-${image_name##*/}.json" "$image_name"
    else
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            -v "$output_dir:/output" aquasec/trivy:latest \
            image --format json --severity "$SEVERITY_LEVELS" \
            --output "/output/trivy-${image_name##*/}.json" "$image_name"
    fi
    
    # 表格格式报告
    if command -v trivy &> /dev/null; then
        trivy image --format table --severity "$SEVERITY_LEVELS" \
            --output "$output_dir/trivy-${image_name##*/}.txt" "$image_name"
    else
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            -v "$output_dir:/output" aquasec/trivy:latest \
            image --format table --severity "$SEVERITY_LEVELS" \
            --output "/output/trivy-${image_name##*/}.txt" "$image_name"
    fi
    
    # SARIF 格式报告（用于 GitHub）
    if command -v trivy &> /dev/null; then
        trivy image --format sarif --severity "$SEVERITY_LEVELS" \
            --output "$output_dir/trivy-${image_name##*/}.sarif" "$image_name"
    else
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            -v "$output_dir:/output" aquasec/trivy:latest \
            image --format sarif --severity "$SEVERITY_LEVELS" \
            --output "/output/trivy-${image_name##*/}.sarif" "$image_name"
    fi
}

# 使用 Grype 扫描
scan_with_grype() {
    local image_name=$1
    local output_dir=$2
    
    echo -e "${BLUE}🔍 使用 Grype 扫描 $image_name...${NC}"
    
    # JSON 格式报告
    grype "$image_name" -o json > "$output_dir/grype-${image_name##*/}.json"
    
    # 表格格式报告
    grype "$image_name" -o table > "$output_dir/grype-${image_name##*/}.txt"
}

# 使用 Docker Scout 扫描
scan_with_docker_scout() {
    local image_name=$1
    local output_dir=$2
    
    echo -e "${BLUE}🔍 使用 Docker Scout 扫描 $image_name...${NC}"
    
    # JSON 格式报告
    docker scout cves --format json "$image_name" > "$output_dir/scout-${image_name##*/}.json"
    
    # 文本格式报告
    docker scout cves "$image_name" > "$output_dir/scout-${image_name##*/}.txt"
}

# 扫描单个镜像
scan_image() {
    local runtime=$1
    local image_name="gitea-runtime-${runtime}"
    local full_image_name="${image_name}:latest"
    
    echo -e "\n${BLUE}🔒 扫描镜像: $image_name${NC}"
    
    # 检查镜像是否存在
    if ! docker image inspect "$full_image_name" &>/dev/null; then
        echo -e "${YELLOW}⚠️  镜像 $full_image_name 不存在，跳过扫描${NC}"
        return 1
    fi
    
    local image_report_dir="$REPORT_DIR/$runtime"
    mkdir -p "$image_report_dir"
    
    # 使用各种工具扫描
    for tool in "${SCAN_TOOLS[@]}"; do
        case $tool in
            "trivy")
                scan_with_trivy "$full_image_name" "$image_report_dir"
                ;;
            "grype")
                scan_with_grype "$full_image_name" "$image_report_dir"
                ;;
            "docker-scout")
                scan_with_docker_scout "$full_image_name" "$image_report_dir"
                ;;
        esac
    done
    
    # 生成镜像特定的汇总报告
    generate_image_summary "$runtime" "$image_report_dir"
}

# 生成镜像汇总报告
generate_image_summary() {
    local runtime=$1
    local report_dir=$2
    local summary_file="$report_dir/summary.md"
    
    echo "# $runtime 镜像安全扫描汇总" > "$summary_file"
    echo "扫描时间: $(date)" >> "$summary_file"
    echo "镜像: gitea-runtime-$runtime:latest" >> "$summary_file"
    echo "" >> "$summary_file"
    
    # 统计各工具发现的漏洞数量
    echo "## 漏洞统计" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "| 扫描工具 | 严重 | 高危 | 中危 | 低危 | 总计 |" >> "$summary_file"
    echo "|----------|------|------|------|------|------|" >> "$summary_file"
    
    for tool in "${SCAN_TOOLS[@]}"; do
        local json_file="$report_dir/${tool}-gitea-runtime-${runtime}.json"
        if [ -f "$json_file" ]; then
            case $tool in
                "trivy")
                    local critical=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$json_file" 2>/dev/null || echo "0")
                    local high=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$json_file" 2>/dev/null || echo "0")
                    local medium=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "$json_file" 2>/dev/null || echo "0")
                    local low=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="LOW")] | length' "$json_file" 2>/dev/null || echo "0")
                    local total=$((critical + high + medium + low))
                    echo "| Trivy | $critical | $high | $medium | $low | $total |" >> "$summary_file"
                    ;;
                "grype")
                    local critical=$(jq -r '[.matches[] | select(.vulnerability.severity=="Critical")] | length' "$json_file" 2>/dev/null || echo "0")
                    local high=$(jq -r '[.matches[] | select(.vulnerability.severity=="High")] | length' "$json_file" 2>/dev/null || echo "0")
                    local medium=$(jq -r '[.matches[] | select(.vulnerability.severity=="Medium")] | length' "$json_file" 2>/dev/null || echo "0")
                    local low=$(jq -r '[.matches[] | select(.vulnerability.severity=="Low")] | length' "$json_file" 2>/dev/null || echo "0")
                    local total=$((critical + high + medium + low))
                    echo "| Grype | $critical | $high | $medium | $low | $total |" >> "$summary_file"
                    ;;
            esac
        fi
    done
    
    echo "" >> "$summary_file"
    
    # 添加修复建议
    echo "## 修复建议" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "1. **立即修复严重和高危漏洞**" >> "$summary_file"
    echo "2. **更新基础镜像到最新版本**" >> "$summary_file"
    echo "3. **移除不必要的包和依赖**" >> "$summary_file"
    echo "4. **定期重新扫描和更新**" >> "$summary_file"
    echo "" >> "$summary_file"
    
    # 添加详细报告链接
    echo "## 详细报告" >> "$summary_file"
    echo "" >> "$summary_file"
    for tool in "${SCAN_TOOLS[@]}"; do
        local txt_file="${tool}-gitea-runtime-${runtime}.txt"
        local json_file="${tool}-gitea-runtime-${runtime}.json"
        if [ -f "$report_dir/$txt_file" ]; then
            echo "- [$tool 文本报告]($txt_file)" >> "$summary_file"
        fi
        if [ -f "$report_dir/$json_file" ]; then
            echo "- [$tool JSON 报告]($json_file)" >> "$summary_file"
        fi
    done
}

# 生成基线报告
generate_baseline() {
    local baseline_file="$REPORT_DIR/baseline.json"
    
    echo -e "${BLUE}📊 生成基线报告...${NC}"
    
    local baseline_data="{\"timestamp\":\"$(date -Iseconds)\",\"images\":{}}"
    
    for runtime in markdown asustor template latex; do
        if [ -n "$ONLY_IMAGE" ] && [ "$ONLY_IMAGE" != "$runtime" ]; then
            continue
        fi
        
        local image_report_dir="$REPORT_DIR/$runtime"
        local trivy_json="$image_report_dir/trivy-gitea-runtime-${runtime}.json"
        
        if [ -f "$trivy_json" ]; then
            local vuln_count=$(jq -r '[.Results[]?.Vulnerabilities[]?] | length' "$trivy_json" 2>/dev/null || echo "0")
            baseline_data=$(echo "$baseline_data" | jq --arg runtime "$runtime" --arg count "$vuln_count" '.images[$runtime] = {"vulnerability_count": ($count | tonumber)}')
        fi
    done
    
    echo "$baseline_data" > "$baseline_file"
    echo -e "${GREEN}✅ 基线报告已保存: $baseline_file${NC}"
}

# 与基线比较
compare_with_baseline() {
    local baseline_file="$REPORT_DIR/baseline.json"
    local comparison_file="$REPORT_DIR/comparison.md"
    
    if [ ! -f "$baseline_file" ]; then
        echo -e "${YELLOW}⚠️  基线文件不存在，跳过比较${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📈 与基线比较...${NC}"
    
    echo "# 安全扫描基线比较报告" > "$comparison_file"
    echo "比较时间: $(date)" >> "$comparison_file"
    echo "" >> "$comparison_file"
    
    echo "| 镜像 | 基线漏洞数 | 当前漏洞数 | 变化 | 趋势 |" >> "$comparison_file"
    echo "|------|------------|------------|------|------|" >> "$comparison_file"
    
    for runtime in markdown asustor template latex; do
        if [ -n "$ONLY_IMAGE" ] && [ "$ONLY_IMAGE" != "$runtime" ]; then
            continue
        fi
        
        local baseline_count=$(jq -r ".images.${runtime}.vulnerability_count // 0" "$baseline_file" 2>/dev/null || echo "0")
        
        local image_report_dir="$REPORT_DIR/$runtime"
        local trivy_json="$image_report_dir/trivy-gitea-runtime-${runtime}.json"
        local current_count="0"
        
        if [ -f "$trivy_json" ]; then
            current_count=$(jq -r '[.Results[]?.Vulnerabilities[]?] | length' "$trivy_json" 2>/dev/null || echo "0")
        fi
        
        local change=$((current_count - baseline_count))
        local trend="→"
        if [ $change -gt 0 ]; then
            trend="↗️ +$change"
        elif [ $change -lt 0 ]; then
            trend="↘️ $change"
        fi
        
        echo "| $runtime | $baseline_count | $current_count | $change | $trend |" >> "$comparison_file"
    done
    
    echo -e "${GREEN}✅ 基线比较完成: $comparison_file${NC}"
}

# 生成总体汇总报告
generate_overall_summary() {
    local summary_file="$REPORT_DIR/security_summary.md"
    
    echo -e "${BLUE}📋 生成总体汇总报告...${NC}"
    
    echo "# Docker 镜像安全扫描总体汇总" > "$summary_file"
    echo "扫描时间: $(date)" >> "$summary_file"
    echo "使用的扫描工具: ${SCAN_TOOLS[*]}" >> "$summary_file"
    echo "严重性级别: $SEVERITY_LEVELS" >> "$summary_file"
    echo "" >> "$summary_file"
    
    echo "## 镜像扫描状态" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "| 镜像 | 状态 | 报告 |" >> "$summary_file"
    echo "|------|------|------|" >> "$summary_file"
    
    for runtime in markdown asustor template latex; do
        if [ -n "$ONLY_IMAGE" ] && [ "$ONLY_IMAGE" != "$runtime" ]; then
            continue
        fi
        
        local image_report_dir="$REPORT_DIR/$runtime"
        local summary_exists="❌"
        local report_link="N/A"
        
        if [ -f "$image_report_dir/summary.md" ]; then
            summary_exists="✅"
            report_link="[$runtime/summary.md]($runtime/summary.md)"
        fi
        
        echo "| gitea-runtime-$runtime | $summary_exists | $report_link |" >> "$summary_file"
    done
    
    echo "" >> "$summary_file"
    
    # 添加安全建议
    echo "## 安全建议" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "### 立即行动项" >> "$summary_file"
    echo "1. 修复所有严重(CRITICAL)级别漏洞" >> "$summary_file"
    echo "2. 修复高危(HIGH)级别漏洞" >> "$summary_file"
    echo "3. 更新基础镜像到最新稳定版本" >> "$summary_file"
    echo "" >> "$summary_file"
    
    echo "### 持续改进" >> "$summary_file"
    echo "1. 建立定期扫描计划" >> "$summary_file"
    echo "2. 集成安全扫描到 CI/CD 流程" >> "$summary_file"
    echo "3. 监控新漏洞披露" >> "$summary_file"
    echo "4. 实施最小权限原则" >> "$summary_file"
    echo "" >> "$summary_file"
    
    echo -e "${GREEN}✅ 总体汇总报告完成: $summary_file${NC}"
}

# 主函数
main() {
    parse_args "$@"
    
    echo -e "${BLUE}🚀 开始 Docker 镜像安全扫描...${NC}"
    echo "注册表: $REGISTRY"
    echo "报告目录: $REPORT_DIR"
    echo "严重性级别: $SEVERITY_LEVELS"
    echo "扫描工具: ${SCAN_TOOLS[*]}"
    
    # 创建报告目录
    mkdir -p "$REPORT_DIR"
    
    # 检查扫描工具
    check_scan_tools
    
    # 扫描镜像
    if [ -n "$ONLY_IMAGE" ]; then
        scan_image "$ONLY_IMAGE"
    else
        for runtime in markdown asustor template latex; do
            scan_image "$runtime"
        done
    fi
    
    # 生成基线报告
    if [ "$GENERATE_BASELINE" = true ]; then
        generate_baseline
    fi
    
    # 与基线比较
    if [ "$COMPARE_BASELINE" = true ]; then
        compare_with_baseline
    fi
    
    # 生成总体汇总
    generate_overall_summary
    
    echo -e "\n${GREEN}✨ 安全扫描完成！${NC}"
    echo -e "查看汇总报告: ${BLUE}$REPORT_DIR/security_summary.md${NC}"
}

# 执行主函数
main "$@"
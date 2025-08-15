#!/bin/bash

# =================================================================
# 版本管理脚本 - 语义化版本控制
# =================================================================

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

VERSION_FILE="VERSION"
CHANGELOG_FILE="CHANGELOG.md"

# 显示帮助信息
show_help() {
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  current                 显示当前版本"
    echo "  bump [major|minor|patch] 升级版本"
    echo "  tag                     创建Git标签"
    echo "  changelog               生成变更日志"
    echo "  release                 执行完整发布流程"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示此帮助信息"
    echo "  -m, --message MESSAGE   发布消息"
    echo "  --dry-run               预览模式，不执行实际操作"
    echo ""
    echo "示例:"
    echo "  $0 current              # 显示当前版本"
    echo "  $0 bump patch           # 升级补丁版本"
    echo "  $0 bump minor -m \"添加新功能\""
    echo "  $0 release --dry-run    # 预览发布流程"
    exit 0
}

# 获取当前版本
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "0.0.0"
    fi
}

# 解析版本号
parse_version() {
    local version=$1
    echo "$version" | sed -E 's/^v?([0-9]+)\.([0-9]+)\.([0-9]+).*$/\1 \2 \3/'
}

# 升级版本
bump_version() {
    local bump_type=$1
    local current_version=$(get_current_version)
    
    read -r major minor patch <<< $(parse_version "$current_version")
    
    case $bump_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            echo -e "${RED}❌ 无效的版本类型: $bump_type${NC}"
            echo "支持的类型: major, minor, patch"
            exit 1
            ;;
    esac
    
    local new_version="${major}.${minor}.${patch}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[预览] 版本将从 $current_version 升级到 $new_version${NC}"
    else
        echo "$new_version" > "$VERSION_FILE"
        echo -e "${GREEN}✅ 版本已升级: $current_version → $new_version${NC}"
    fi
    
    echo "$new_version"
}

# 创建Git标签
create_git_tag() {
    local version=$1
    local message=${2:-"Release v$version"}
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  不在Git仓库中，跳过标签创建${NC}"
        return 0
    fi
    
    local tag_name="v$version"
    
    if git tag -l | grep -q "^$tag_name$"; then
        echo -e "${YELLOW}⚠️  标签 $tag_name 已存在${NC}"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[预览] 将创建Git标签: $tag_name${NC}"
        echo -e "${YELLOW}[预览] 标签消息: $message${NC}"
    else
        git tag -a "$tag_name" -m "$message"
        echo -e "${GREEN}✅ Git标签已创建: $tag_name${NC}"
    fi
}

# 生成变更日志
generate_changelog() {
    local version=$1
    local date=$(date +%Y-%m-%d)
    
    if [ ! -f "$CHANGELOG_FILE" ]; then
        cat > "$CHANGELOG_FILE" << EOF
# 变更日志

本文档记录了项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本控制遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增
### 变更
### 修复
### 移除

EOF
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[预览] 将在变更日志中添加版本 $version${NC}"
    else
        # 在"未发布"部分之前插入新版本
        sed -i "/## \[未发布\]/a\\
\\
## [$version] - $date\\
\\
### 新增\\
- 版本管理系统\\
- 语义化版本控制\\
\\
### 变更\\
- 改进项目文档结构\\
\\
### 修复\\
- 无\\
\\
### 移除\\
- 无" "$CHANGELOG_FILE"
        
        echo -e "${GREEN}✅ 变更日志已更新${NC}"
    fi
}

# 检查工作目录状态
check_git_status() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return 0
    fi
    
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}⚠️  工作目录有未提交的更改${NC}"
        if [ "$DRY_RUN" != true ]; then
            read -p "是否继续? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${RED}❌ 发布已取消${NC}"
                exit 1
            fi
        fi
    fi
}

# 执行完整发布流程
release() {
    local bump_type=${1:-"patch"}
    local message=$2
    
    echo -e "${BLUE}🚀 开始发布流程...${NC}"
    
    # 检查Git状态
    check_git_status
    
    # 升级版本
    local new_version=$(bump_version "$bump_type")
    
    # 生成变更日志
    generate_changelog "$new_version"
    
    # 创建Git标签
    local tag_message=${message:-"Release v$new_version"}
    create_git_tag "$new_version" "$tag_message"
    
    if [ "$DRY_RUN" != true ]; then
        echo -e "\n${GREEN}✨ 发布完成！${NC}"
        echo -e "版本: ${BLUE}v$new_version${NC}"
        echo -e "下一步: 推送标签到远程仓库"
        echo -e "  ${YELLOW}git push origin v$new_version${NC}"
        echo -e "  ${YELLOW}git push origin main${NC}"
    else
        echo -e "\n${YELLOW}💡 这是预览模式，没有执行实际更改${NC}"
    fi
}

# 主函数
main() {
    local command=""
    local bump_type="patch"
    local message=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -m|--message)
                message="$2"
                shift 2
                ;;
            current|bump|tag|changelog|release)
                command="$1"
                shift
                ;;
            major|minor|patch)
                bump_type="$1"
                shift
                ;;
            *)
                echo "未知选项: $1"
                show_help
                ;;
        esac
    done
    
    # 执行命令
    case $command in
        "current")
            echo "当前版本: $(get_current_version)"
            ;;
        "bump")
            bump_version "$bump_type"
            ;;
        "tag")
            local version=$(get_current_version)
            create_git_tag "$version" "$message"
            ;;
        "changelog")
            local version=$(get_current_version)
            generate_changelog "$version"
            ;;
        "release")
            release "$bump_type" "$message"
            ;;
        "")
            echo -e "${RED}❌ 缺少命令${NC}"
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $command${NC}"
            show_help
            ;;
    esac
}

# 执行主函数
main "$@"
#!/bin/bash

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 设置默认值
REGISTRY="git.httpx.online/kenyon"
PLATFORMS="linux/amd64,linux/arm64"
PUSH=false
TAG="latest"
NO_CACHE=false
CLEAN_CACHE=false

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -r, --registry      设置 Docker 注册表 (默认: $REGISTRY)"
    echo "  -p, --platforms     设置构建平台 (默认: $PLATFORMS)"
    echo "  --only NAME         仅构建指定的镜像 (e.g., markdown)"
    echo "  --tag TAG           指定镜像的标签 (默认: latest)"
    echo "  --push              构建后推送到注册表"
    echo "  --no-cache          禁用构建缓存"
    echo "  --clean-cache       清理本地构建缓存"
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
            -p|--platforms)
                PLATFORMS="$2"
                shift 2
                ;;
            --only)
                ONLY_IMAGE="$2"
                shift 2
                ;;
            --tag)
                TAG="$2"
                shift 2
                ;;
            --push)
                PUSH=true
                shift
                ;;
            --no-cache)
                NO_CACHE=true
                shift
                ;;
            --clean-cache)
                CLEAN_CACHE=true
                shift
                ;;
            *)
                echo "未知选项: $1"
                show_help
                ;;
        esac
    done
}

# 构建和推送 Docker 镜像
build_and_push() {
    local runtime_name=$1
    local image_name="gitea-runtime-${runtime_name}"
    local full_image_name="${REGISTRY}/${image_name}"
    local context_path="./runtime-${runtime_name}"
    local version=$(git describe --tags --always 2>/dev/null || echo "dev")

    echo -e "\n${BLUE}🔨 构建镜像: ${full_image_name}:${TAG}${NC}"
    
    # 处理缓存清理
    if [ "$CLEAN_CACHE" = true ]; then
        echo -e "${BLUE}🧹 清理构建缓存...${NC}"
        # 清理 registry 缓存（如果需要的话）
        echo "Registry cache cleanup would be handled by registry TTL"
    fi

    local build_command="docker buildx build \
        --platform \"$PLATFORMS\" \
        --tag \"$full_image_name:${TAG}\" \
        --build-arg \"GITEA_VERSION=$version\" \
        --build-arg \"BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')\" \
        --progress=plain"
    
    # LaTeX镜像特殊处理
    if [ "$runtime_name" = "latex" ]; then
        echo -e "${BLUE}🔧 LaTeX镜像特殊配置...${NC}"
        # 为LaTeX构建启用更详细的输出
        build_command="$build_command --progress=plain"
    fi
    
    # 暂时禁用缓存以确保构建稳定性
    if [ "$NO_CACHE" = true ]; then
        build_command="$build_command --no-cache"
    fi
    # 注意：缓存已暂时禁用，如需启用请使用 registry 缓存

    if [ "$PUSH" = true ]; then
        build_command="$build_command --push"
    else
        # 如果不推送，则加载到本地 Docker daemon
        build_command="$build_command --load"
    fi
    
    build_command="$build_command \"$context_path\""

    echo -e "${BLUE}执行构建命令:${NC}"
    echo "$build_command"
    
    eval $build_command

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 镜像 ${full_image_name}:${TAG} 构建完成${NC}"
    else
        echo -e "${RED}❌ 构建镜像 ${full_image_name}:${TAG} 失败${NC}"
        echo -e "${RED}构建命令: $build_command${NC}"
        exit 1
    fi
}

# 主函数
main() {
    parse_args "$@"

    if [ -z "$ONLY_IMAGE" ]; then
        echo -e "${RED}错误: --only 参数是必需的。${NC}"
        show_help
    fi

    build_and_push "$ONLY_IMAGE"
}

# 执行主函数
main "$@"
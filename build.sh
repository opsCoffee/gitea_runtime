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
        rm -rf /tmp/.buildx-cache
    fi
    
    # 确保本地缓存目录存在
    mkdir -p /tmp/.buildx-cache

    local build_command="docker buildx build \
        --platform \"$PLATFORMS\" \
        --tag \"$full_image_name:${TAG}\" \
        --build-arg \"GITEA_VERSION=$version\" \
        --build-arg \"BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')\" \
        --progress=plain"
    
    # 根据选项添加缓存配置（必须在 --push/--load 之前）
    if [ "$NO_CACHE" = false ]; then
        # 确保缓存目录存在且有正确的权限
        if [ -d "/tmp/.buildx-cache" ] && [ "$(ls -A /tmp/.buildx-cache 2>/dev/null)" ]; then
            build_command="$build_command \
                --cache-from \"type=local,src=/tmp/.buildx-cache\""
        fi
        build_command="$build_command \
            --cache-to \"type=local,dest=/tmp/.buildx-cache,mode=max\""
    else
        build_command="$build_command --no-cache"
    fi
    
    # LaTeX 镜像特殊处理
    if [ "$runtime_name" = "latex" ]; then
        build_command="$build_command \
            --build-arg BUILDKIT_INLINE_CACHE=1"
        
        # 为 LaTeX 镜像暂时只构建 AMD64，避免 ARM64 模拟器问题
        echo -e "${BLUE}⚠️  LaTeX 镜像暂时只构建 AMD64 架构以避免 ARM64 模拟器问题${NC}"
        build_command=$(echo "$build_command" | sed 's/--platform "[^"]*"/--platform "linux\/amd64"/')
    fi

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
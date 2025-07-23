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

    local build_command="docker buildx build \
        --platform \"$PLATFORMS\" \
        --tag \"$full_image_name:${TAG}\" \
        --build-arg \"GITEA_VERSION=$version\" \
        --build-arg \"BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')\" \
        --cache-from \"type=registry,ref=$full_image_name:cache\" \
        --cache-to \"type=registry,ref=$full_image_name:cache,mode=max\" \
        --progress=plain \
        \"$context_path\""

    if [ "$PUSH" = true ]; then
        build_command="$build_command --push"
    else
        # 如果不推送，则加载到本地 Docker daemon
        build_command="$build_command --load"
    fi

    eval $build_command

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 镜像 ${full_image_name}:${TAG} 构建完成${NC}"
    else
        echo -e "${RED}❌ 构建镜像 ${full_image_name}:${TAG} 失败${NC}"
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
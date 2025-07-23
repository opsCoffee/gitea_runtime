#!/bin/bash

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 设置默认值
REGISTRY="git.httpx.online/kenyon"
TARGET_DIR="/tmp/docker_images"
PLATFORMS="linux/amd64,linux/arm64"
USE_CACHE=true
PUSH_IMAGES=true
SAVE_IMAGES=true
TEST_IMAGES=true

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -r, --registry      设置 Docker 注册表 (默认: $REGISTRY)"
    echo "  -d, --dir           设置保存镜像的目录 (默认: $TARGET_DIR)"
    echo "  -p, --platforms     设置构建平台 (默认: $PLATFORMS)"
    echo "  --no-cache          禁用缓存"
    echo "  --no-push           不推送镜像到注册表"
    echo "  --no-save           不保存镜像为 tar 文件"
    echo "  --no-test           不测试镜像"
    echo "  --only NAME         仅构建指定的镜像 (可选值: markdown, asustor, template, latex)"
    echo ""
    echo "示例:"
    echo "  $0 --no-push --no-save"
    echo "  $0 --only markdown"
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
            -d|--dir)
                TARGET_DIR="$2"
                shift 2
                ;;
            -p|--platforms)
                PLATFORMS="$2"
                shift 2
                ;;
            --no-cache)
                USE_CACHE=false
                shift
                ;;
            --no-push)
                PUSH_IMAGES=false
                shift
                ;;
            --no-save)
                SAVE_IMAGES=false
                shift
                ;;
            --no-test)
                TEST_IMAGES=false
                shift
                ;;
            --only)
                ONLY_IMAGE="$2"
                shift 2
                ;;
            *)
                echo "未知选项: $1"
                show_help
                ;;
        esac
    done
}

# 构建、标记、推送和删除 Docker 镜像的功能
handle_docker_image() {
    local image_name=$1
    local image_tag=$2
    local dockerfile_path=$3
    local build_args=""
    
    echo -e "\n${BLUE}🔨 构建镜像: ${image_name}:${image_tag}${NC}"
    
    # 添加版本信息
    VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")
    BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    
    # 设置构建参数
    if [ "$USE_CACHE" = true ]; then
        build_args="--cache-from type=registry,ref=${REGISTRY}/${image_name}:cache"
    else
        build_args="--no-cache"
    fi
    
    # 构建镜像
    docker buildx build $build_args \
        --platform ${PLATFORMS} \
        --build-arg VERSION=${VERSION} \
        --build-arg BUILD_DATE=${BUILD_DATE} \
        -t ${image_name}:${image_tag} \
        -t ${REGISTRY}/${image_name}:${image_tag} \
        -t ${REGISTRY}/${image_name}:latest \
        -f ${dockerfile_path} .
    
    # 如果启用了缓存，则更新缓存
    if [ "$USE_CACHE" = true ]; then
        echo -e "${YELLOW}📦 更新缓存...${NC}"
        docker buildx build --cache-to type=registry,ref=${REGISTRY}/${image_name}:cache,mode=max \
            -t ${REGISTRY}/${image_name}:cache \
            -f ${dockerfile_path} . --push
    fi
    
    # 如果启用了推送，则推送镜像
    if [ "$PUSH_IMAGES" = true ]; then
        echo -e "${YELLOW}📤 推送镜像到注册表...${NC}"
        docker push ${REGISTRY}/${image_name}:${image_tag}
        docker push ${REGISTRY}/${image_name}:latest
    fi
    
    echo -e "${GREEN}✅ 镜像 ${image_name}:${image_tag} 构建完成${NC}"
}

# 将 Docker 镜像保存为 tar 文件的功能
save_docker_image() {
    local image_name=$1
    local image_tag=$2
    local target_dir=$3
    
    echo -e "\n${YELLOW}💾 保存镜像: ${image_name}:${image_tag}${NC}"
    docker save -o ${target_dir}/${image_name}_${image_tag}.tar ${image_name}:${image_tag}
    echo -e "${GREEN}✅ 镜像已保存到 ${target_dir}/${image_name}_${image_tag}.tar${NC}"
}

# 主函数
main() {
    # 解析命令行参数
    parse_args "$@"
    
    echo -e "${BLUE}🚀 开始构建 Docker 镜像...${NC}"
    echo -e "注册表: ${REGISTRY}"
    echo -e "平台: ${PLATFORMS}"
    echo -e "使用缓存: ${USE_CACHE}"
    echo -e "推送镜像: ${PUSH_IMAGES}"
    echo -e "保存镜像: ${SAVE_IMAGES}"
    echo -e "测试镜像: ${TEST_IMAGES}"
    
    # 确保存在目标目录
    if [ "$SAVE_IMAGES" = true ] && [ ! -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}📁 创建目录: ${TARGET_DIR}${NC}"
        mkdir -p "$TARGET_DIR"
    fi
    
    # 定义镜像细节
    declare -A image_map
    image_map["markdown"]="gitea-runtime-markdown:latest:runtime-markdown/Dockerfile"
    image_map["asustor"]="gitea-runtime-asustor:latest:runtime-asustor/Dockerfile"
    image_map["template"]="gitea-runtime-template:latest:runtime-template/Dockerfile"
    image_map["latex"]="gitea-runtime-latex:latest:runtime-latex/Dockerfile"
    
    # 处理镜像
    if [ -n "$ONLY_IMAGE" ]; then
        if [ -n "${image_map[$ONLY_IMAGE]}" ]; then
            IFS=':' read -r name tag dockerfile <<< "${image_map[$ONLY_IMAGE]}"
            handle_docker_image $name $tag $dockerfile
            
            # 如果启用了保存，则保存镜像
            if [ "$SAVE_IMAGES" = true ]; then
                save_docker_image $name $tag $TARGET_DIR
            fi
            
            # 如果启用了测试，则测试镜像
            if [ "$TEST_IMAGES" = true ]; then
                chmod +x ./test_images.sh
                ./test_images.sh $ONLY_IMAGE
            fi
        else
            echo -e "${RED}❌ 未知镜像: ${ONLY_IMAGE}${NC}"
            exit 1
        fi
    else
        # 处理所有镜像
        for key in "${!image_map[@]}"; do
            IFS=':' read -r name tag dockerfile <<< "${image_map[$key]}"
            handle_docker_image $name $tag $dockerfile
            
            # 如果启用了保存，则保存镜像
            if [ "$SAVE_IMAGES" = true ]; then
                save_docker_image $name $tag $TARGET_DIR
            fi
        done
        
        # 如果启用了测试，则测试所有镜像
        if [ "$TEST_IMAGES" = true ]; then
            chmod +x ./test_images.sh
            ./test_images.sh
        fi
    fi
    
    # 清理
    echo -e "\n${YELLOW}🧹 清理...${NC}"
    docker images --filter "dangling=true" --format '{{.ID}}' | xargs -r docker rmi
    docker builder prune --force --filter until=24h
    
    echo -e "\n${GREEN}✨ 所有操作完成${NC}"
}

# 执行主函数
main "$@"

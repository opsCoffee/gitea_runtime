#!/bin/bash

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值
REGISTRY="git.httpx.online/kenyon"
TAG="latest"

# 显示帮助信息
show_help() {
    echo "用法: $0 [runtime_name] [选项]"
    echo ""
    echo "参数:"
    echo "  runtime_name      要测试的镜像名称 (e.g., markdown)"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -r, --registry      设置 Docker 注册表 (默认: $REGISTRY)"
    echo "  --tag TAG           指定要测试的镜像标签 (默认: latest)"
    exit 0
}

# 解析参数
RUNTIME_NAME=$1
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        *)
            echo "未知选项: $1"
            show_help
            ;;
    esac
done

if [ -z "$RUNTIME_NAME" ]; then
    echo -e "${RED}错误: 缺少 runtime_name 参数。${NC}"
    show_help
fi

IMAGE_NAME="gitea-runtime-${RUNTIME_NAME}"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}"

# 测试镜像
test_image() {
    echo -e "\n${BLUE}🧪 开始测试镜像: ${FULL_IMAGE_NAME}:${TAG}${NC}"

    # 拉取镜像
    echo "拉取镜像..."
    docker pull "${FULL_IMAGE_NAME}:${TAG}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 拉取镜像 ${FULL_IMAGE_NAME}:${TAG} 失败${NC}"
        exit 1
    fi

    # 运行基本测试
    echo "运行容器并检查基本命令..."
    if docker run --rm "${FULL_IMAGE_NAME}:${TAG}" echo "Hello from container"; then
        echo -e "${GREEN}✅ 基本测试通过${NC}"
    else
        echo -e "${RED}❌ 基本测试失败${NC}"
        exit 1
    fi

    # 更多特定于运行时的测试可以在这里添加
    # ...

    echo -e "${GREEN}✨ 镜像 ${FULL_IMAGE_NAME}:${TAG} 测试完成。${NC}"
}

test_image

#!/bin/bash
# test_images.sh - 自动化测试脚本，用于验证构建的镜像功能

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] [镜像类型]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -r, --registry      设置 Docker 注册表 (默认: git.httpx.online/kenyon)"
    echo "  -t, --tag           设置镜像标签 (默认: latest)"
    echo "  --date-tag          使用日期标签 (格式: v年月日，例如 v20250723)"
    echo ""
    echo "镜像类型:"
    echo "  markdown            仅测试 Markdown 运行时镜像"
    echo "  asustor            仅测试 ASUSTOR 运行时镜像"
    echo "  template           仅测试模板处理运行时镜像"
    echo "  latex              仅测试 LaTeX 运行时镜像"
    echo ""
    echo "示例:"
    echo "  $0 --registry git.httpx.online/kenyon --tag latest"
    echo "  $0 --date-tag markdown"
    exit 0
}

# 如果没有参数或有帮助参数，显示帮助
if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

# 默认注册表和标签
REGISTRY="git.httpx.online/kenyon"
TAG="latest"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -r|--registry)
      REGISTRY="$2"
      shift 2
      ;;
    -t|--tag)
      TAG="$2"
      shift 2
      ;;
    --date-tag)
      TAG="v$(date -u +'%Y%m%d')"
      shift
      ;;
    *)
      IMAGE_TYPE="$1"
      shift
      ;;
  esac
done

# 测试函数
run_test() {
  local test_name=$1
  local command=$2
  
  echo -e "\n🔍 测试: ${test_name}"
  echo "执行: $command"
  
  if eval "$command"; then
    echo -e "${GREEN}✅ 通过${NC}"
    return 0
  else
    echo -e "${RED}❌ 失败${NC}"
    return 1
  fi
}

# 测试 Markdown 运行时
test_markdown_runtime() {
  echo -e "\n📋 测试 Markdown 运行时镜像 (标签: ${TAG})"
  
  run_test "markdownlint-cli2 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-markdown:${TAG} markdownlint-cli2 --version"
  run_test "Node.js 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-markdown:${TAG} node --version"
  run_test "Python 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-markdown:${TAG} python --version"
  
  # 创建测试 Markdown 文件
  echo "# Test Markdown\n\nThis is a test." > /tmp/test.md
  
  # 测试 Markdown 格式化功能
  run_test "Markdown 格式检查" "docker run --rm -v /tmp/test.md:/app/test.md ${REGISTRY}/gitea-runtime-markdown:${TAG} markdownlint-cli2 /app/test.md"
  
  # 清理
  rm -f /tmp/test.md
}

# 测试 ASUSTOR 运行时
test_asustor_runtime() {
  echo -e "\n📋 测试 ASUSTOR 运行时镜像 (标签: ${TAG})"
  
  run_test "Python 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} python3 --version"
  run_test "Node.js 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} node --version"
  run_test "npm 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} npm --version"
  run_test "git 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} git --version"
}

# 测试模板处理运行时
test_template_runtime() {
  echo -e "\n📋 测试模板处理运行时镜像 (标签: ${TAG})"
  
  run_test "Nuclei 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} nuclei -version"
  run_test "Node.js 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} node --version"
  run_test "Python 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} python3 --version"
}

# 测试 LaTeX 运行时
test_latex_runtime() {
  echo -e "\n📋 测试 LaTeX 运行时镜像 (标签: ${TAG})"
  
  run_test "xelatex 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-latex:${TAG} xelatex --version"
  run_test "Node.js 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-latex:${TAG} node --version"
  
  # 创建测试 LaTeX 文件
  cat > /tmp/test.tex << EOF
\\documentclass{article}
\\begin{document}
Hello, World!
\\end{document}
EOF
  
  # 测试 LaTeX 编译功能
  run_test "LaTeX 编译测试" "docker run --rm -v /tmp/test.tex:/app/test.tex ${REGISTRY}/gitea-runtime-latex:${TAG} xelatex -interaction=nonstopmode /app/test.tex"
  
  # 清理
  rm -f /tmp/test.tex
}

# 主函数
main() {
  echo "🚀 开始测试 Docker 镜像..."
  echo "使用注册表: ${REGISTRY}"
  echo "使用镜像标签: ${TAG}"
  
  # 根据参数或默认测试所有镜像
  if [ "$IMAGE_TYPE" == "markdown" ]; then
    test_markdown_runtime
  elif [ "$IMAGE_TYPE" == "asustor" ]; then
    test_asustor_runtime
  elif [ "$IMAGE_TYPE" == "template" ]; then
    test_template_runtime
  elif [ "$IMAGE_TYPE" == "latex" ]; then
    test_latex_runtime
  else
    test_markdown_runtime
    test_asustor_runtime
    test_template_runtime
    test_latex_runtime
  fi
  
  echo -e "\n✨ 测试完成"
}

# 执行主函数
main
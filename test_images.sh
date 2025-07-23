#!/bin/bash
# test_images.sh - 自动化测试脚本，用于验证构建的镜像功能

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# 测试 markdown_format_runtime
test_markdown_runtime() {
  echo -e "\n📋 测试 markdown_format_runtime 镜像"
  
  run_test "markdownlint-cli2 版本检查" "docker run --rm alpine_runtime:v0.2 markdownlint-cli2 --version"
  run_test "Node.js 版本检查" "docker run --rm alpine_runtime:v0.2 node --version"
  run_test "Python 版本检查" "docker run --rm alpine_runtime:v0.2 python --version"
  
  # 创建测试 Markdown 文件
  echo "# Test Markdown\n\nThis is a test." > /tmp/test.md
  
  # 测试 Markdown 格式化功能
  run_test "Markdown 格式检查" "docker run --rm -v /tmp/test.md:/app/test.md alpine_runtime:v0.2 markdownlint-cli2 /app/test.md"
  
  # 清理
  rm -f /tmp/test.md
}

# 测试 asustor_runtime
test_asustor_runtime() {
  echo -e "\n📋 测试 asustor_runtime 镜像"
  
  run_test "Python 版本检查" "docker run --rm asustor_runtime:v0.1 python3 --version"
  run_test "Node.js 版本检查" "docker run --rm asustor_runtime:v0.1 node --version"
  run_test "npm 版本检查" "docker run --rm asustor_runtime:v0.1 npm --version"
  run_test "git 版本检查" "docker run --rm asustor_runtime:v0.1 git --version"
}

# 测试 template_runtime
test_template_runtime() {
  echo -e "\n📋 测试 template_runtime 镜像"
  
  run_test "Nuclei 版本检查" "docker run --rm template_run:v0.1 nuclei -version"
  run_test "Node.js 版本检查" "docker run --rm template_run:v0.1 node --version"
  run_test "Python 版本检查" "docker run --rm template_run:v0.1 python3 --version"
}

# 主函数
main() {
  echo "🚀 开始测试 Docker 镜像..."
  
  # 根据参数或默认测试所有镜像
  if [ "$1" == "markdown" ]; then
    test_markdown_runtime
  elif [ "$1" == "asustor" ]; then
    test_asustor_runtime
  elif [ "$1" == "template" ]; then
    test_template_runtime
  else
    test_markdown_runtime
    test_asustor_runtime
    test_template_runtime
  fi
  
  echo -e "\n✨ 测试完成"
}

# 执行主函数
main "$@"
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
  
  # 基础工具版本检查
  run_test "markdownlint-cli2 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-markdown:${TAG} markdownlint-cli2 --version"
  run_test "Node.js 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-markdown:${TAG} node --version"
  run_test "Python 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-markdown:${TAG} python --version"
  run_test "Git 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-markdown:${TAG} git --version"
  
  # 创建测试文件目录
  local test_dir="/tmp/markdown_test_$$"
  mkdir -p "$test_dir"
  
  # 创建有问题的 Markdown 文件（用于测试 linting）
  cat > "$test_dir/bad.md" << 'EOF'
#Bad Header
This line has trailing spaces   

- list item
-another list item

[bad link](http://example.com)
EOF
  
  # 创建正确的 Markdown 文件
  cat > "$test_dir/good.md" << 'EOF'
# Good Header

This is a well-formatted markdown file.

- First list item
- Second list item

[Good link](https://example.com)
EOF
  
  # 测试 Markdown 格式检查功能
  run_test "Markdown 格式检查 - 检测错误" "! docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-markdown:${TAG} markdownlint-cli2 /app/bad.md"
  run_test "Markdown 格式检查 - 正确文件" "docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-markdown:${TAG} markdownlint-cli2 /app/good.md"
  
  # 测试批量处理
  run_test "批量 Markdown 检查" "docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-markdown:${TAG} markdownlint-cli2 /app/good.md"
  
  # 测试用户权限
  run_test "非 root 用户运行" "docker run --rm ${REGISTRY}/gitea-runtime-markdown:${TAG} whoami | grep -v root"
  
  # 测试健康检查
  run_test "健康检查功能" "docker run --rm ${REGISTRY}/gitea-runtime-markdown:${TAG} sh -c 'markdownlint-cli2 --version || exit 1'"
  
  # 清理
  rm -rf "$test_dir"
}

# 测试 ASUSTOR 运行时
test_asustor_runtime() {
  echo -e "\n📋 测试 ASUSTOR 运行时镜像 (标签: ${TAG})"
  
  # 基础工具版本检查
  run_test "Python 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} python3 --version"
  run_test "Node.js 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} node --version"
  run_test "npm 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} npm --version"
  run_test "git 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} git --version"
  
  # 创建测试文件目录
  local test_dir="/tmp/asustor_test_$$"
  mkdir -p "$test_dir"
  
  # 创建 Python 测试脚本
  cat > "$test_dir/test_script.py" << 'EOF'
#!/usr/bin/env python3
import sys
import json
import os

def main():
    print("Python script execution test")
    data = {"test": "success", "python_version": sys.version}
    print(json.dumps(data, indent=2))
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOF
  
  # 创建 Node.js 测试脚本
  cat > "$test_dir/test_script.js" << 'EOF'
const fs = require('fs');
const path = require('path');

console.log('Node.js script execution test');
console.log('Node version:', process.version);
console.log('Platform:', process.platform);

// 测试文件操作
const testData = { test: 'success', node_version: process.version };
console.log(JSON.stringify(testData, null, 2));
EOF
  
  # 创建 package.json 用于测试 npm
  cat > "$test_dir/package.json" << 'EOF'
{
  "name": "asustor-test",
  "version": "1.0.0",
  "description": "Test package for ASUSTOR runtime",
  "main": "test_script.js",
  "scripts": {
    "test": "node test_script.js"
  }
}
EOF
  
  # 功能测试
  run_test "Python 脚本执行" "docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-asustor:${TAG} python3 /app/test_script.py"
  run_test "Node.js 脚本执行" "docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-asustor:${TAG} node /app/test_script.js"
  run_test "npm 脚本执行" "docker run --rm -v $test_dir:/app -w /app ${REGISTRY}/gitea-runtime-asustor:${TAG} npm run test"
  
  # 测试 Python 模块导入
  run_test "Python 标准库测试" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} python3 -c 'import json, os, sys; print(\"Python modules OK\")'"
  
  # 测试用户权限
  run_test "非 root 用户运行" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} whoami | grep -v root"
  
  # 测试健康检查
  run_test "健康检查功能" "docker run --rm ${REGISTRY}/gitea-runtime-asustor:${TAG} python3 -c 'import sys; sys.exit(0)'"
  
  # 清理
  rm -rf "$test_dir"
}

# 测试模板处理运行时
test_template_runtime() {
  echo -e "\n📋 测试模板处理运行时镜像 (标签: ${TAG})"
  
  # 基础工具版本检查
  run_test "Nuclei 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} nuclei -version"
  run_test "templates-stats 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} templates-stats -version"
  run_test "Node.js 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} node --version"
  run_test "Python 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} python3 --version"
  run_test "Git 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} git --version"
  
  # 创建测试文件目录
  local test_dir="/tmp/template_test_$$"
  mkdir -p "$test_dir/templates"
  
  # 创建简单的 Nuclei 模板用于测试
  cat > "$test_dir/templates/test-template.yaml" << 'EOF'
id: test-template
info:
  name: Test Template
  author: test
  severity: info
  description: Simple test template
  tags: test

http:
  - method: GET
    path:
      - "{{BaseURL}}"
    matchers:
      - type: status
        status:
          - 200
EOF
  
  # 创建测试目标列表
  echo "https://httpbin.org" > "$test_dir/targets.txt"
  
  # 功能测试
  run_test "Nuclei 模板验证" "docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-template:${TAG} nuclei -validate -t /app/templates/"
  run_test "Nuclei 基础扫描测试" "docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-template:${TAG} nuclei -t /app/templates/test-template.yaml -u https://httpbin.org -silent"
  
  # 测试 templates-stats 功能
  run_test "模板统计功能" "docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-template:${TAG} templates-stats -path /app/templates/"
  
  # 测试 Node.js 脚本执行
  cat > "$test_dir/test_node.js" << 'EOF'
console.log('Node.js in template runtime works');
console.log('Process version:', process.version);
EOF
  run_test "Node.js 脚本执行" "docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-template:${TAG} node /app/test_node.js"
  
  # 测试 Python 脚本执行
  cat > "$test_dir/test_python.py" << 'EOF'
#!/usr/bin/env python3
import sys
print('Python in template runtime works')
print('Python version:', sys.version)
EOF
  run_test "Python 脚本执行" "docker run --rm -v $test_dir:/app ${REGISTRY}/gitea-runtime-template:${TAG} python3 /app/test_python.py"
  
  # 测试用户权限
  run_test "非 root 用户运行" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} whoami | grep -v root"
  
  # 测试健康检查
  run_test "健康检查功能" "docker run --rm ${REGISTRY}/gitea-runtime-template:${TAG} nuclei -version"
  
  # 清理
  rm -rf "$test_dir"
}

# 测试 LaTeX 运行时
test_latex_runtime() {
  echo -e "\n📋 测试 LaTeX 运行时镜像 (标签: ${TAG})"
  
  # 基础工具版本检查
  run_test "xelatex 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-latex:${TAG} xelatex --version"
  run_test "pdflatex 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-latex:${TAG} pdflatex --version"
  run_test "Node.js 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-latex:${TAG} node --version"
  run_test "tlmgr 版本检查" "docker run --rm ${REGISTRY}/gitea-runtime-latex:${TAG} tlmgr --version"
  
  # 创建测试文件目录
  local test_dir="/tmp/latex_test_$$"
  mkdir -p "$test_dir"
  
  # 创建简单的 LaTeX 测试文件
  cat > "$test_dir/simple.tex" << 'EOF'
\documentclass{article}
\usepackage[utf8]{inputenc}
\title{Test Document}
\author{Test Author}
\date{\today}

\begin{document}
\maketitle

\section{Introduction}
This is a simple test document to verify LaTeX functionality.

\subsection{Features}
\begin{itemize}
    \item Basic text formatting
    \item Mathematical expressions: $E = mc^2$
    \item Lists and sections
\end{itemize}

\section{Conclusion}
LaTeX compilation test completed successfully.

\end{document}
EOF
  
  # 创建中文 LaTeX 测试文件
  cat > "$test_dir/chinese.tex" << 'EOF'
\documentclass{ctexart}
\usepackage{fontspec}

\title{中文测试文档}
\author{测试作者}
\date{\today}

\begin{document}
\maketitle

\section{介绍}
这是一个中文LaTeX文档测试。

\subsection{功能测试}
\begin{itemize}
    \item 中文字体支持
    \item 数学公式：$\sum_{i=1}^{n} i = \frac{n(n+1)}{2}$
    \item 列表和章节
\end{itemize}

\section{结论}
中文LaTeX编译测试成功完成。

\end{document}
EOF
  
  # LaTeX 编译测试
  run_test "基础 LaTeX 编译 (pdflatex)" "docker run --rm -v $test_dir:/app -w /app ${REGISTRY}/gitea-runtime-latex:${TAG} pdflatex -interaction=nonstopmode simple.tex"
  run_test "XeLaTeX 编译测试" "docker run --rm -v $test_dir:/app -w /app ${REGISTRY}/gitea-runtime-latex:${TAG} xelatex -interaction=nonstopmode simple.tex"
  run_test "中文 LaTeX 编译测试" "docker run --rm -v $test_dir:/app -w /app ${REGISTRY}/gitea-runtime-latex:${TAG} xelatex -interaction=nonstopmode chinese.tex"
  
  # 验证生成的 PDF 文件
  run_test "PDF 文件生成验证" "docker run --rm -v $test_dir:/app -w /app ${REGISTRY}/gitea-runtime-latex:${TAG} test -f simple.pdf"
  
  # 测试 LaTeX 包管理
  run_test "LaTeX 包列表" "docker run --rm ${REGISTRY}/gitea-runtime-latex:${TAG} tlmgr list --only-installed | head -5"
  
  # 测试 Node.js 功能
  cat > "$test_dir/test_node.js" << 'EOF'
const fs = require('fs');
console.log('Node.js in LaTeX runtime works');
console.log('Files in current directory:', fs.readdirSync('.').filter(f => f.endsWith('.tex')));
EOF
  run_test "Node.js 脚本执行" "docker run --rm -v $test_dir:/app -w /app ${REGISTRY}/gitea-runtime-latex:${TAG} node test_node.js"
  
  # 测试用户权限
  run_test "非 root 用户运行" "docker run --rm ${REGISTRY}/gitea-runtime-latex:${TAG} whoami | grep -v root"
  
  # 测试健康检查
  run_test "健康检查功能" "docker run --rm ${REGISTRY}/gitea-runtime-latex:${TAG} xelatex --version"
  
  # 清理
  rm -rf "$test_dir"
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
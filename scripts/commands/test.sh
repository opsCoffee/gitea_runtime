#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck disable=SC1091
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck disable=SC1091
# shellcheck source=../lib/runtime.sh
source "$REPO_ROOT/scripts/lib/runtime.sh"

REGISTRY="$DEFAULT_REGISTRY"
TAG="$DEFAULT_TAG"
ONLY_RUNTIMES=""
FULL_IMAGE_NAME=""
DRY_RUN=false
TARGET_RUNTIMES=()
TEMP_DIR=""
DOCKER_ARGS=()
TEST_COMMAND=()
CURRENT_RUNTIME=""
CURRENT_IMAGE_NAME=""

show_help() {
    cat <<EOF
用法: ./scripts/runtimectl.sh test [选项]

默认行为: 不指定 --only 时，测试全部支持的 runtime

选项:
  -h, --help          显示此帮助信息
  -r, --registry      设置 Docker 注册表 (默认: $DEFAULT_REGISTRY)
  --only RUNTIMES     仅测试指定 runtime，支持逗号分隔多个值
  --image-name NAME   指定完整镜像名，仅支持单 runtime
  --tag TAG           指定镜像标签 (默认: $DEFAULT_TAG)
  --dry-run           仅输出测试命令，不实际执行

支持的 runtime:
  ${SUPPORTED_RUNTIMES[*]}
EOF
}

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    TEMP_DIR=""
}

trap cleanup EXIT

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -r|--registry)
                require_value "$1" "${2-}"
                REGISTRY="$2"
                shift 2
                ;;
            --only)
                require_value "$1" "${2-}"
                ONLY_RUNTIMES="$2"
                shift 2
                ;;
            --image-name)
                require_value "$1" "${2-}"
                FULL_IMAGE_NAME="$2"
                shift 2
                ;;
            --tag)
                require_value "$1" "${2-}"
                TAG="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                error_exit "未知选项: $1"
                ;;
        esac
    done
}

collect_runtimes() {
    resolve_target_runtimes "$ONLY_RUNTIMES"
    TARGET_RUNTIMES=("${PARSED_RUNTIMES[@]}")
}

validate_runtime_options() {
    if [[ -n "$FULL_IMAGE_NAME" && ${#TARGET_RUNTIMES[@]} -ne 1 ]]; then
        error_exit "--image-name 仅支持单个 runtime 使用"
    fi
}

resolve_image_name() {
    if [[ -n "$FULL_IMAGE_NAME" ]]; then
        CURRENT_IMAGE_NAME="$FULL_IMAGE_NAME"
        return
    fi

    CURRENT_IMAGE_NAME="$(runtime_image_repo "$REGISTRY" "$CURRENT_RUNTIME")"
}

prepare_test_fixture() {
    TEMP_DIR="$(mktemp -d)"
    DOCKER_ARGS=(--rm -v "$TEMP_DIR:/workspace" -w /workspace)
    TEST_COMMAND=()

    case "$CURRENT_RUNTIME" in
        markdown)
            cat > "$TEMP_DIR/sample.md" <<'EOF'
# 示例标题

这是一段用于测试 markdownlint-cli2 的最小 Markdown 文档。
EOF
            TEST_COMMAND=(markdownlint-cli2 sample.md)
            ;;
        latex)
            cat > "$TEMP_DIR/document.tex" <<'EOF'
\documentclass{article}
\begin{document}
Hello, LaTeX!
\end{document}
EOF
            TEST_COMMAND=(xelatex -interaction=nonstopmode -halt-on-error document.tex)
            ;;
        template)
            mkdir -p "$TEMP_DIR/templates"
            cat > "$TEMP_DIR/templates/sample.yaml" <<'EOF'
id: sample-template
info:
  name: Sample Template
  author: test
  severity: info
http:
  - method: GET
    path:
      - "{{BaseURL}}/"
    matchers:
      - type: status
        status:
          - 200
EOF
            TEST_COMMAND=(nuclei -validate -t templates)
            ;;
        asustor)
            cat > "$TEMP_DIR/script.py" <<'EOF'
print("asustor-runtime-ok")
EOF
            TEST_COMMAND=(python3 script.py)
            ;;
        base)
            cat > "$TEMP_DIR/index.js" <<'EOF'
console.log('base-runtime-ok');
EOF
            TEST_COMMAND=(node index.js)
            ;;
        maven)
            cat > "$TEMP_DIR/pom.xml" <<'EOF'
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>demo</groupId>
  <artifactId>runtime-check</artifactId>
  <version>1.0.0</version>
</project>
EOF
            TEST_COMMAND=(mvn -q -DskipTests help:evaluate -Dexpression=project.artifactId -DforceStdout)
            ;;
        claudecode)
            mkdir -p "$TEMP_DIR/.git/hooks"
            TEST_COMMAND=(install-claude-git-hook /workspace)
            ;;
        *)
            error_exit "未为 runtime ${CURRENT_RUNTIME} 定义测试命令"
            ;;
    esac
}

check_local_image() {
    docker image inspect "${CURRENT_IMAGE_NAME}:${TAG}" >/dev/null 2>&1
}

pull_image_if_needed() {
    if check_local_image; then
        log_success "✅ 镜像已存在于本地，跳过拉取步骤"
        return
    fi

    log_info "拉取镜像..."
    docker pull "${CURRENT_IMAGE_NAME}:${TAG}"
}

print_test_command() {
    log_info "测试命令:"
    printf 'docker run '
    print_command "${DOCKER_ARGS[@]}" "${CURRENT_IMAGE_NAME}:${TAG}" "${TEST_COMMAND[@]}"
}

run_single_runtime_test() {
    resolve_image_name
    prepare_test_fixture

    log_info ""
    log_info "🧪 开始测试镜像: ${CURRENT_IMAGE_NAME}:${TAG}"
    print_test_command

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[dry-run] 跳过实际执行"
        cleanup
        return
    fi

    require_command docker
    pull_image_if_needed

    if docker run "${DOCKER_ARGS[@]}" "${CURRENT_IMAGE_NAME}:${TAG}" "${TEST_COMMAND[@]}"; then
        log_success "✅ runtime 级测试通过"
    else
        error_exit "runtime 级测试失败"
    fi

    log_success "✨ 镜像 ${CURRENT_IMAGE_NAME}:${TAG} 测试完成"
    cleanup
}

main() {
    local runtime_name

    parse_args "$@"
    validate_registry "$REGISTRY"
    validate_tag "$TAG"
    collect_runtimes
    validate_runtime_options

    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        CURRENT_RUNTIME="$runtime_name"
        CURRENT_IMAGE_NAME=""
        run_single_runtime_test
    done
}

main "$@"

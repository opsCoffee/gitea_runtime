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
PLATFORMS="$DEFAULT_PLATFORMS"
TAG="$DEFAULT_TAG"
PUSH=false
NO_CACHE=false
CLEAN_CACHE=false
DRY_RUN=false
ONLY_RUNTIMES=""
TARGET_RUNTIMES=()
BUILD_COMMAND=()

show_help() {
    cat <<EOF
用法: ./scripts/runtimectl.sh build [选项]

默认行为: 不指定 --only 时，构建全部支持的 runtime

选项:
  -h, --help          显示此帮助信息
  -r, --registry      设置 Docker 注册表 (默认: $DEFAULT_REGISTRY)
  -p, --platforms     设置构建平台 (默认: $DEFAULT_PLATFORMS)
  --only RUNTIMES     仅构建指定 runtime，支持逗号分隔多个值
  --tag TAG           指定镜像标签 (默认: $DEFAULT_TAG)
  --push              构建后推送到注册表
  --no-cache          禁用构建缓存
  --clean-cache       清理本地构建缓存
  --dry-run           仅输出构建命令，不实际执行

支持的 runtime:
  ${SUPPORTED_RUNTIMES[*]}
EOF
}

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
            -p|--platforms)
                require_value "$1" "${2-}"
                PLATFORMS="$2"
                shift 2
                ;;
            --only)
                require_value "$1" "${2-}"
                ONLY_RUNTIMES="$2"
                shift 2
                ;;
            --tag)
                require_value "$1" "${2-}"
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
    local runtime_name

    resolve_target_runtimes "$ONLY_RUNTIMES"
    TARGET_RUNTIMES=("${PARSED_RUNTIMES[@]}")

    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        validate_runtime_context "$runtime_name"
    done
}

build_runtime_command() {
    local runtime_name="$1"
    local full_image_repo
    local version
    local build_date

    full_image_repo="$(runtime_image_repo "$REGISTRY" "$runtime_name")"
    version="$(git -C "$REPO_ROOT" describe --tags --always 2>/dev/null || echo "dev")"
    build_date="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

    BUILD_COMMAND=(
        docker buildx build
        --platform "$PLATFORMS"
        --tag "${full_image_repo}:${TAG}"
        --build-arg "GITEA_VERSION=$version"
        --build-arg "BUILD_DATE=$build_date"
        --progress=plain
    )

    if [[ "$NO_CACHE" == true ]]; then
        BUILD_COMMAND+=(--no-cache)
    fi

    if [[ "$PUSH" == true ]]; then
        BUILD_COMMAND+=(--push)
    elif [[ "$PLATFORMS" == *","* ]]; then
        log_warn "⚠️  多平台构建不会自动加载到本地 Docker daemon"
        log_warn "💡 如需本地测试，请使用 --platforms linux/amd64"
    else
        BUILD_COMMAND+=(--load)
    fi

    BUILD_COMMAND+=("$(runtime_context_dir "$runtime_name")")
}

build_runtime() {
    local runtime_name="$1"
    local full_image_repo

    full_image_repo="$(runtime_image_repo "$REGISTRY" "$runtime_name")"
    build_runtime_command "$runtime_name"

    log_info ""
    log_info "🔨 构建镜像: ${full_image_repo}:${TAG}"

    if [[ "$CLEAN_CACHE" == true ]]; then
        log_info "🧹 清理构建缓存..."
        echo "Registry cache cleanup would be handled by registry TTL"
    fi

    log_info "执行构建命令:"
    print_command "${BUILD_COMMAND[@]}"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[dry-run] 跳过实际执行"
        return
    fi

    require_command docker
    if "${BUILD_COMMAND[@]}"; then
        log_success "✅ 镜像 ${full_image_repo}:${TAG} 构建完成"
        return
    fi

    error_exit "构建镜像 ${full_image_repo}:${TAG} 失败"
}

main() {
    local runtime_name

    parse_args "$@"
    validate_registry "$REGISTRY"
    validate_tag "$TAG"
    validate_platforms "$PLATFORMS"
    collect_runtimes

    log_info "本次将构建以下 runtime: ${TARGET_RUNTIMES[*]}"
    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        build_runtime "$runtime_name"
    done
}

main "$@"

#!/bin/bash

if [[ -n "${GITEA_RUNTIME_COMMON_SH_LOADED:-}" ]]; then
    return 0
fi
GITEA_RUNTIME_COMMON_SH_LOADED=1

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}$*${NC}"
}

log_warn() {
    echo -e "${YELLOW}$*${NC}"
}

log_success() {
    echo -e "${GREEN}$*${NC}"
}

log_error() {
    echo -e "${RED}$*${NC}" >&2
}

error_exit() {
    log_error "错误: $*"
    exit 1
}

require_value() {
    local option="$1"
    local value="${2-}"

    if [[ -z "$value" || "$value" == -* ]]; then
        error_exit "${option} 需要提供参数值"
    fi
}

ensure_directory() {
    local dir_path="$1"
    mkdir -p "$dir_path"
}

print_command() {
    printf '%q ' "$@"
    printf '\n'
}

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        error_exit "缺少必需命令: ${command_name}"
    fi
}

validate_registry() {
    local registry="$1"

    if [[ -z "$registry" ]]; then
        error_exit "注册表地址不能为空"
    fi

    if [[ "$registry" =~ [[:space:]] ]]; then
        error_exit "注册表地址不能包含空白字符: ${registry}"
    fi

    if [[ "$registry" == /* || "$registry" == */ || "$registry" == *///* ]]; then
        error_exit "注册表地址格式非法: ${registry}"
    fi
}

validate_tag() {
    local tag="$1"

    if [[ -z "$tag" ]]; then
        error_exit "镜像标签不能为空"
    fi

    if [[ "$tag" =~ [[:space:]] ]]; then
        error_exit "镜像标签不能包含空白字符"
    fi

    if [[ ! "$tag" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]]; then
        error_exit "镜像标签格式非法: ${tag}"
    fi
}

validate_platforms() {
    local platforms="$1"
    local platform
    local -a platform_list

    IFS=',' read -r -a platform_list <<< "$platforms"
    if [[ ${#platform_list[@]} -eq 0 ]]; then
        error_exit "构建平台不能为空"
    fi

    for platform in "${platform_list[@]}"; do
        case "$platform" in
            linux/amd64|linux/arm64)
                ;;
            *)
                error_exit "无效的构建平台: ${platform}。仅支持 linux/amd64,linux/arm64"
                ;;
        esac
    done
}

validate_positive_integer() {
    local name="$1"
    local value="$2"

    if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
        error_exit "${name} 必须是正整数"
    fi
}

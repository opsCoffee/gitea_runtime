#!/bin/bash

if [[ -n "${GITEA_RUNTIME_RUNTIME_SH_LOADED:-}" ]]; then
    return 0
fi
GITEA_RUNTIME_RUNTIME_SH_LOADED=1

SCRIPT_DIR_RUNTIME_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=./config.sh
source "$SCRIPT_DIR_RUNTIME_LIB/config.sh"
# shellcheck disable=SC1091
# shellcheck source=./common.sh
source "$SCRIPT_DIR_RUNTIME_LIB/common.sh"

PARSED_RUNTIMES=()

validate_runtime_name() {
    local runtime_name="$1"

    if [[ ! "$runtime_name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
        error_exit "无效的 runtime 名称: ${runtime_name}"
    fi

    if ! runtime_supported "$runtime_name"; then
        error_exit "不支持的 runtime 名称: ${runtime_name}。支持的 runtime: ${SUPPORTED_RUNTIMES[*]}"
    fi
}

validate_runtime_context() {
    local runtime_name="$1"
    local context_path

    validate_runtime_name "$runtime_name"
    context_path="$(runtime_context_dir "$runtime_name")"

    if [[ ! -d "$context_path" ]]; then
        error_exit "运行时目录不存在: ${context_path}"
    fi

    if [[ ! -f "$context_path/Dockerfile" ]]; then
        error_exit "Dockerfile 不存在: ${context_path}/Dockerfile"
    fi
}

parse_runtime_list() {
    local raw_value="${1-}"
    local runtime_name

    if [[ -z "$raw_value" ]]; then
        error_exit "runtime 列表不能为空"
    fi

    IFS=',' read -r -a PARSED_RUNTIMES <<< "$raw_value"
    if [[ ${#PARSED_RUNTIMES[@]} -eq 0 ]]; then
        error_exit "runtime 列表不能为空"
    fi

    local -a normalized_runtimes=()
    for runtime_name in "${PARSED_RUNTIMES[@]}"; do
        local already_seen=false
        local existing_runtime

        if [[ -z "$runtime_name" ]]; then
            error_exit "runtime 列表中存在空值"
        fi

        validate_runtime_name "$runtime_name"

        for existing_runtime in "${normalized_runtimes[@]}"; do
            if [[ "$existing_runtime" == "$runtime_name" ]]; then
                already_seen=true
                break
            fi
        done

        if [[ "$already_seen" == true ]]; then
            continue
        fi

        normalized_runtimes+=("$runtime_name")
    done

    PARSED_RUNTIMES=("${normalized_runtimes[@]}")
}

resolve_target_runtimes() {
    local raw_value="${1-}"

    if [[ -n "$raw_value" ]]; then
        parse_runtime_list "$raw_value"
        return
    fi

    PARSED_RUNTIMES=("${SUPPORTED_RUNTIMES[@]}")
}

runtime_context_dir() {
    local runtime_name="$1"
    echo "./runtime-${runtime_name}"
}

runtime_image_name() {
    local runtime_name="$1"
    echo "gitea-runtime-${runtime_name}"
}

runtime_image_repo() {
    local registry="$1"
    local runtime_name="$2"
    echo "${registry}/$(runtime_image_name "$runtime_name")"
}

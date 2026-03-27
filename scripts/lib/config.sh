#!/bin/bash

# shellcheck disable=SC2034
# 共享配置常量
DEFAULT_REGISTRY="git.httpx.online/kenyon"
DEFAULT_REGISTRY_HOST="git.httpx.online"
DEFAULT_REGISTRY_NAMESPACE="kenyon"
DEFAULT_PLATFORMS="linux/amd64,linux/arm64"
DEFAULT_TAG="latest"
SUPPORTED_RUNTIMES=(markdown asustor template latex base maven claudecode)

runtime_supported() {
    local runtime_name="$1"
    local runtime

    for runtime in "${SUPPORTED_RUNTIMES[@]}"; do
        if [[ "$runtime" == "$runtime_name" ]]; then
            return 0
        fi
    done

    return 1
}

join_by_comma() {
    local -a items=("$@")
    local IFS=,
    echo "${items[*]}"
}

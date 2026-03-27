#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck disable=SC1091
# shellcheck source=../../scripts/lib/config.sh
source "$REPO_ROOT/scripts/lib/config.sh"

WORKFLOW_FILE="$REPO_ROOT/.github/workflows/build.yml"
WORKFLOW_CONTENT="$(cat "$WORKFLOW_FILE")"
EXPECTED_BUILD_RUNTIMES="markdown, asustor, template, latex, base, maven, claudecode"
EXPECTED_TEST_RUNTIMES="markdown, asustor, template, latex, base, maven, claudecode"
EXPECTED_PUSH_RUNTIMES="markdown, asustor, template, latex, base, maven, claudecode"

error_exit() {
    echo "错误: $1" >&2
    exit 1
}

assert_contains() {
    local expected="$1"
    local description="$2"

    if ! grep -Fq "$expected" <<< "$WORKFLOW_CONTENT"; then
        error_exit "workflow 缺少 ${description}: ${expected}"
    fi
}

main() {
    assert_contains "REGISTRY: ${DEFAULT_REGISTRY_HOST}" "共享 registry host"
    assert_contains "REGISTRY_NAMESPACE: ${DEFAULT_REGISTRY_NAMESPACE}" "共享 registry namespace"
    assert_contains "runtime: [${EXPECTED_BUILD_RUNTIMES}]" "build runtime 列表"
    assert_contains "runtime: [${EXPECTED_TEST_RUNTIMES}]" "test runtime 列表"
    assert_contains "runtime: [${EXPECTED_PUSH_RUNTIMES}]" "push runtime 列表"
    assert_contains "scripts/ci/verify_workflow_config.sh" "配置校验脚本调用"
    assert_contains "bash ./tests/smoke/runtimectl_smoke.sh" "CLI smoke test 调用"
    assert_contains "bash ./scripts/runtimectl.sh build" "统一 build 入口"
    assert_contains "bash ./scripts/runtimectl.sh test" "统一 test 入口"
    assert_contains "./scripts/ci/push_release_image.sh" "发布辅助脚本调用"

    echo "workflow 配置校验通过"
    echo "共享配置支持的 runtime: $(join_by_comma "${SUPPORTED_RUNTIMES[@]}")"
    echo "workflow build runtime: ${EXPECTED_BUILD_RUNTIMES}"
    echo "workflow test runtime: ${EXPECTED_TEST_RUNTIMES}"
    echo "workflow push runtime: ${EXPECTED_PUSH_RUNTIMES}"
    echo "说明: workflow 当前已将全部受支持 runtime 纳入 build/test 显式覆盖集，push 发布集现也纳入 maven 与 claudecode；但 runtime 列表仍由显式配置控制，不自动追随脚本支持全集。"
}

main "$@"

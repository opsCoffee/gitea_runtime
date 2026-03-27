#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI=(bash "$REPO_ROOT/scripts/runtimectl.sh")
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

run_ok() {
    local description="$1"
    shift

    echo "[PASS-CHECK] $description"
    "$@" >/dev/null
}

run_fail() {
    local description="$1"
    shift

    echo "[FAIL-CHECK] $description"
    if "$@" >/dev/null 2>&1; then
        echo "预期失败，但命令成功: $description" >&2
        exit 1
    fi
}

run_ok "顶层帮助" "${CLI[@]}" --help
run_ok "build 帮助" "${CLI[@]}" build --help
run_ok "build dry-run" "${CLI[@]}" build --only markdown,maven --dry-run --platforms linux/amd64
run_ok "test dry-run" "${CLI[@]}" test --only markdown,maven --dry-run
run_ok "security dry-run" "${CLI[@]}" security --only markdown --dry-run --report-dir "$TMP_DIR/security"
run_ok "performance dry-run" "${CLI[@]}" performance --only markdown,maven --dry-run --report-dir "$TMP_DIR/performance"
run_ok "optimize dry-run" "${CLI[@]}" optimize --only markdown --dry-run --report-file "$TMP_DIR/optimization.md"
run_ok "pipeline dry-run" "${CLI[@]}" pipeline --only markdown --quick --dry-run --report-dir "$TMP_DIR/pipeline"
run_ok "version current" "${CLI[@]}" version current

run_fail "未知命令" "${CLI[@]}" unknown
run_fail "非法平台" "${CLI[@]}" build --only markdown --platforms invalid --dry-run
run_fail "test 多 runtime + image-name" "${CLI[@]}" test --only markdown,maven --image-name demo/image --dry-run

echo "Smoke tests passed"

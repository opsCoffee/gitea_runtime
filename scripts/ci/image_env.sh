#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck disable=SC1091
# shellcheck source=../../scripts/lib/config.sh
source "$REPO_ROOT/scripts/lib/config.sh"

runtime_name="${1:?缺少 runtime_name 参数}"
image_tag="${2:?缺少 image_tag 参数}"
output_file="${3:-}"

if ! runtime_supported "$runtime_name"; then
    echo "错误: 不支持的 runtime: $runtime_name" >&2
    exit 1
fi

image_repo="${DEFAULT_REGISTRY_HOST}/${DEFAULT_REGISTRY_NAMESPACE}/gitea-runtime-${runtime_name}"
image_ref="${image_repo}:${image_tag}"
image_tar="${runtime_name}-image.tar"
sarif_file="trivy-results-${runtime_name}.sarif"

emit_vars() {
    echo "IMAGE_REPO=${image_repo}"
    echo "IMAGE_REF=${image_ref}"
    echo "IMAGE_TAR=${image_tar}"
    echo "SARIF_FILE=${sarif_file}"
}

if [[ -n "$output_file" ]]; then
    emit_vars >> "$output_file"
else
    emit_vars
fi

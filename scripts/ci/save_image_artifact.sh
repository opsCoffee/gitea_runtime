#!/bin/bash

set -euo pipefail

image_ref="${1:?缺少 image_ref 参数}"
artifact_path="${2:?缺少 artifact_path 参数}"

docker save "$image_ref" -o "$artifact_path"
echo "已导出镜像制品: $artifact_path"

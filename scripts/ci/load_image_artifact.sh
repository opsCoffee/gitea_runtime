#!/bin/bash

set -euo pipefail

artifact_path="${1:?缺少 artifact_path 参数}"
image_repo="${2:?缺少 image_repo 参数}"

docker load -i "$artifact_path"
docker images | grep "$image_repo"
echo "已加载并校验镜像: $image_repo"

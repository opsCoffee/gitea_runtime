#!/bin/bash

# 构建、标记、推送和删除 Docker 镜像的功能
handle_docker_image() {
    local image_name=$1
    local image_tag=$2
    local dockerfile_path=$3
    local registry="git.httpx.online/kenyon"
    
    docker buildx build -t ${image_name}:${image_tag} -f ${dockerfile_path} . 
    docker tag ${image_name}:${image_tag} ${registry}/${image_name}:${image_tag}
    docker push ${registry}/${image_name}:${image_tag}
    docker rmi ${registry}/${image_name}:${image_tag}
}

# 定义镜像细节
images=(
    "template_run:v0.1:template_runtime/Dockerfile"
    "alpine_runtime:v0.2:markdown_format_runtime/Dockerfile"
    "asustor_runtime:v0.1:asustor_runtime/Dockerfile"
)

# 循环处理每个镜像
for image in "${images[@]}"; do
    IFS=':' read -r name tag dockerfile <<< "$image"
    handle_docker_image $name $tag $dockerfile
done

# 设置镜像的保存目录
TARGET_DIR="/tmp/docker_images"

# 确保存在目标目录
if [ ! -d "$TARGET_DIR" ]; then
    echo "Directory $TARGET_DIR does not exist. Creating it."
    mkdir -p "$TARGET_DIR"
fi

# 将 Docker 映像保存为 tar 文件的功能
save_docker_image() {
    local image_name=$1
    local image_tag=$2
    local target_dir=$3
    
    docker save -o ${target_dir}/${image_name}_${image_tag}.tar ${image_name}:${image_tag}
}

# 循环保存每个镜像
for image in "${images[@]}"; do
    IFS=':' read -r name tag dockerfile <<< "$image"
    save_docker_image $name $tag $TARGET_DIR
done

# Remove dangling images
docker images --filter "dangling=true" --format '{{.ID}}' | xargs -r docker rmi

# Prune unused builder data
docker builder prune --force


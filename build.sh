docker buildx build -t template_run:v0.1 -f template_runtime/Dockerfile .
docker buildx build -t alpine_runtime:v0.2 -f markdown_format_runtime/Dockerfile .
mkdir /tmp/docker_images
docker save -o /tmp/docker_images/template_run_v0.1.tar template_run:v0.1
docker save -o /tmp/docker_images/alpine_runtime_v0.2.tar alpine_runtime:v0.2

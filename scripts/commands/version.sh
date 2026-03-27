#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck disable=SC1091
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"

VERSION_FILE="$REPO_ROOT/VERSION"
CHANGELOG_FILE="$REPO_ROOT/CHANGELOG.md"
DRY_RUN=false
ALLOW_DIRTY=false

show_help() {
    cat <<'EOF'
用法: ./scripts/runtimectl.sh version <command> [选项]

命令:
  current                  显示当前版本
  bump [major|minor|patch] 升级版本号
  tag                      为当前版本创建 Git 标签
  changelog                为当前版本生成变更日志片段
  release [major|minor|patch]
                           执行版本升级、变更日志更新和打标签

选项:
  -h, --help               显示此帮助信息
  -m, --message MESSAGE    指定标签消息
  --allow-dirty            允许在脏工作区执行
  --dry-run                仅预览，不执行实际写入
EOF
}

get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
        return
    fi

    echo "0.0.0"
}

parse_version() {
    local version="$1"
    echo "$version" | sed -E 's/^v?([0-9]+)\.([0-9]+)\.([0-9]+).*$/\1 \2 \3/'
}

check_git_status() {
    if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        return
    fi

    if [[ "$ALLOW_DIRTY" == true || "$DRY_RUN" == true ]]; then
        return
    fi

    if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
        error_exit "工作区存在未提交改动；如确有需要，请显式传入 --allow-dirty"
    fi
}

bump_version() {
    local bump_type="$1"
    local current_version
    local major
    local minor
    local patch

    current_version="$(get_current_version)"
    read -r major minor patch <<< "$(parse_version "$current_version")"

    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            error_exit "无效的版本类型: ${bump_type}"
            ;;
    esac

    local new_version="${major}.${minor}.${patch}"
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[dry-run] 版本将从 ${current_version} 升级到 ${new_version}"
    else
        echo "$new_version" > "$VERSION_FILE"
        log_success "✅ 版本已升级: ${current_version} -> ${new_version}"
    fi

    echo "$new_version"
}

create_git_tag() {
    local version="$1"
    local message="${2:-Release v$version}"
    local tag_name="v$version"

    if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        log_warn "⚠️  当前不在 Git 仓库中，跳过标签创建"
        return
    fi

    if git -C "$REPO_ROOT" tag -l | grep -q "^${tag_name}$"; then
        log_warn "⚠️  标签 ${tag_name} 已存在，跳过创建"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[dry-run] 将创建 Git 标签: ${tag_name}"
        return
    fi

    git -C "$REPO_ROOT" tag -a "$tag_name" -m "$message"
    log_success "✅ Git 标签已创建: ${tag_name}"
}

generate_changelog() {
    local version="$1"
    local release_date

    release_date="$(date +%Y-%m-%d)"
    if [[ ! -f "$CHANGELOG_FILE" ]]; then
        cat > "$CHANGELOG_FILE" <<'EOF'
# 变更日志

本文档记录了项目的所有重要变更。

## [未发布]

### 新增
### 变更
### 修复
### 移除
EOF
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[dry-run] 将在变更日志中加入版本 ${version}"
        return
    fi

    local changelog_content
    changelog_content=$(cat "$CHANGELOG_FILE")
    {
        echo "# 变更日志"
        echo
        echo "本文档记录了项目的所有重要变更。"
        echo
        echo "## [未发布]"
        echo
        echo "### 新增"
        echo "### 变更"
        echo "### 修复"
        echo "### 移除"
        echo
        echo "## [${version}] - ${release_date}"
        echo
        echo "### 新增"
        echo "- 待补充"
        echo
        echo "### 变更"
        echo "- 待补充"
        echo
        echo "### 修复"
        echo "- 待补充"
        echo
        echo "### 移除"
        echo "- 无"
        echo
        printf '%s\n' "$changelog_content" | tail -n +10
    } > "${CHANGELOG_FILE}.tmp"
    mv "${CHANGELOG_FILE}.tmp" "$CHANGELOG_FILE"
    log_success "✅ 变更日志已更新"
}

release_version() {
    local bump_type="$1"
    local message="$2"
    local new_version

    check_git_status
    new_version="$(bump_version "$bump_type")"
    generate_changelog "$new_version"
    create_git_tag "$new_version" "$message"
}

main() {
    local command_name="${1-}"
    local bump_type="patch"
    local message=""

    if [[ -z "$command_name" || "$command_name" == "-h" || "$command_name" == "--help" ]]; then
        show_help
        return
    fi
    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            major|minor|patch)
                bump_type="$1"
                shift
                ;;
            -m|--message)
                require_value "$1" "${2-}"
                message="$2"
                shift 2
                ;;
            --allow-dirty)
                ALLOW_DIRTY=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                return
                ;;
            *)
                error_exit "未知选项: $1"
                ;;
        esac
    done

    case "$command_name" in
        current)
            echo "当前版本: $(get_current_version)"
            ;;
        bump)
            check_git_status
            bump_version "$bump_type"
            ;;
        tag)
            check_git_status
            create_git_tag "$(get_current_version)" "$message"
            ;;
        changelog)
            check_git_status
            generate_changelog "$(get_current_version)"
            ;;
        release)
            release_version "$bump_type" "$message"
            ;;
        *)
            error_exit "未知命令: ${command_name}"
            ;;
    esac
}

main "$@"

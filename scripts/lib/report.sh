#!/bin/bash

if [[ -n "${GITEA_RUNTIME_REPORT_SH_LOADED:-}" ]]; then
    return 0
fi
GITEA_RUNTIME_REPORT_SH_LOADED=1

# shellcheck disable=SC1091
# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

report_reset() {
    local report_file="$1"
    shift

    : > "$report_file"
    if [[ $# -gt 0 ]]; then
        report_append_lines "$report_file" "$@"
    fi
}

report_append_line() {
    local report_file="$1"
    local line="$2"

    printf '%s\n' "$line" >> "$report_file"
}

report_append_lines() {
    local report_file="$1"
    shift
    local line

    for line in "$@"; do
        report_append_line "$report_file" "$line"
    done
}

report_append_blank() {
    local report_file="$1"
    printf '\n' >> "$report_file"
}

report_append_file_from_line() {
    local report_file="$1"
    local source_file="$2"
    local start_line="$3"

    if [[ ! -f "$source_file" ]]; then
        return
    fi

    tail -n +"$start_line" "$source_file" >> "$report_file"
}

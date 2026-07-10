#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "usage: $0 <template_repo> <project_name> [binary_name]" >&2
    echo "example: $0 gh:YOUR-ORG/cuda-template 01-copy" >&2
    exit 1
fi

template_repo="$1"
project_name="$2"
binary_name="${3:-$2}"

if ! command -v copier >/dev/null 2>&1; then
    echo "copier is not installed. Install it first, then rerun this command." >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd "${script_dir}/.." && pwd)"
target_dir="${workspace_root}/${project_name}"

if [[ -e "${target_dir}" ]]; then
    echo "target already exists: ${target_dir}" >&2
    exit 1
fi

copier copy \
    --data project_name="${project_name}" \
    --data binary_name="${binary_name}" \
    "${template_repo}" \
    "${target_dir}"

echo "${target_dir}"

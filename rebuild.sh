#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scripts_dir="$repo_root/scripts"

if [[ ! -d "$scripts_dir" ]]; then
  echo "Missing scripts directory: $scripts_dir" >&2
  exit 1
fi

build_scripts=(
  "$scripts_dir/build_manuscript.sh"
  "$scripts_dir/build_pdf.sh"
  "$scripts_dir/build_epub.sh"
  "$scripts_dir/build_website.sh"
)

for build_script in "${build_scripts[@]}"; do
  if [[ ! -f "$build_script" ]]; then
    echo "Missing build script: $build_script" >&2
    exit 1
  fi

  echo "Running ${build_script#$repo_root/}"
  "$build_script"
done

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scripts_dir="$repo_root/scripts"

if [[ ! -d "$scripts_dir" ]]; then
  echo "Missing scripts directory: $scripts_dir" >&2
  exit 1
fi

shopt -s nullglob
build_scripts=("$scripts_dir"/build_*.sh)
shopt -u nullglob

if (( ${#build_scripts[@]} == 0 )); then
  echo "No build scripts found in $scripts_dir" >&2
  exit 1
fi

for build_script in "${build_scripts[@]}"; do
  echo "Running ${build_script#$repo_root/}"
  "$build_script"
done

#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
input_md="$repo_root/Proof of Human.md"
cover_image="$repo_root/proof-of-human.png"
output_epub="$repo_root/Proof of Human.epub"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    printf 'Required file not found: %s\n' "$1" >&2
    exit 1
  fi
}

require_command pandoc
require_file "$script_dir/build_manuscript.sh"
require_file "$cover_image"

bash "$script_dir/build_manuscript.sh"
require_file "$input_md"

pandoc "$input_md" \
  --from markdown \
  --to epub3 \
  --toc \
  --toc-depth=2 \
  --split-level=2 \
  --metadata title="Proof of Human" \
  --metadata author="Joshua Szepietowski" \
  --metadata lang="en-US" \
  --resource-path="$repo_root" \
  --epub-cover-image="$cover_image" \
  --output "$output_epub"

printf 'Built %s\n' "$output_epub"

#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
chapters_dir="$repo_root/chapters"
output_file="$repo_root/Proof of Human.md"

if [[ ! -d "$chapters_dir" ]]; then
  echo "Missing chapters directory: $chapters_dir" >&2
  exit 1
fi

{
  printf '# Proof of Human\n\n'
  printf 'Joshua Szepietowski\n'
} > "$output_file"

while IFS= read -r act_dir; do
  act_title="$(basename "$act_dir")"

  {
    printf '\n## %s\n' "$act_title"
  } >> "$output_file"

  while IFS= read -r chapter_file; do
    chapter_title="$(basename "$chapter_file" .md)"

    {
      printf '\n### %s\n\n' "$chapter_title"
      awk '
        NR == 1 && /^# / { skipped_heading = 1; next }
        skipped_heading && NR == 2 && $0 == "" { next }
        { print }
      ' "$chapter_file"
    } >> "$output_file"
  done < <(find "$act_dir" -mindepth 1 -maxdepth 1 -type f -name '*.md' | sort)
done < <(find "$chapters_dir" -mindepth 1 -maxdepth 1 -type d | sort)

printf 'Built %s\n' "$output_file"

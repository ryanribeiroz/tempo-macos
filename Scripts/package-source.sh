#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
output_file="${1:-${project_dir}/../../outputs/Tempo-source.tar.gz}"
project_parent="${project_dir:h}"
project_name="${project_dir:t}"

/bin/mkdir -p "${output_file:h}"
/usr/bin/tar -czf "$output_file" \
  --exclude="${project_name}/.git" \
  --exclude="${project_name}/.build" \
  --exclude="${project_name}/work" \
  -C "$project_parent" \
  "$project_name"

echo "$output_file"

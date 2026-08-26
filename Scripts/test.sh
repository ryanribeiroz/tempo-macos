#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
build_dir="${project_dir}/.build"

cd "$project_dir"
env CLANG_MODULE_CACHE_PATH="$build_dir/ModuleCache" \
  SWIFTPM_MODULECACHE_OVERRIDE="$build_dir/ModuleCache" \
  swift test --disable-sandbox --scratch-path "$build_dir" "$@"

#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
output_dir="${1:-${project_dir}/../../outputs}"
build_dir="${project_dir}/.build"
app_dir="${output_dir}/Tempo.app"

cd "$project_dir"
env CLANG_MODULE_CACHE_PATH="$build_dir/ModuleCache" \
  SWIFTPM_MODULECACHE_OVERRIDE="$build_dir/ModuleCache" \
  swift build -c release --disable-sandbox --scratch-path "$build_dir"

/bin/rm -rf "$app_dir"
/bin/mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
/bin/cp "$build_dir/release/Tempo" "$app_dir/Contents/MacOS/Tempo"
/bin/cp "$project_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"

if [[ -d "$project_dir/Resources/AppIcon.xcassets" ]]; then
  /usr/bin/xcrun actool "$project_dir/Resources/AppIcon.xcassets" \
    --compile "$app_dir/Contents/Resources" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$build_dir/AppIcon-info.plist" >/dev/null
fi

/usr/bin/codesign --force --deep --sign - \
  --requirements '=designated => identifier "com.local.tempo"' \
  "$app_dir"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$output_dir/Tempo-macOS.zip"

echo "$app_dir"

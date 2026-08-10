#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SVG="$ROOT_DIR/assets/icons/vaultmark_master_source.svg"
MASTER_PNG="$ROOT_DIR/assets/icons/vaultmark_master_1024.png"

render_from_master() {
  local size="$1"
  local output="$2"
  mkdir -p "$(dirname "$output")"
  sips -z "$size" "$size" "$MASTER_PNG" --out "$output" >/dev/null
}

TEMP_DIR="$(mktemp -d /tmp/pass_doc_icon.XXXXXX)"
trap 'rm -rf "$TEMP_DIR"' EXIT

qlmanage -t -s 1024 -o "$TEMP_DIR" "$SOURCE_SVG" >/dev/null
cp "$TEMP_DIR/$(basename "$SOURCE_SVG").png" "$MASTER_PNG"

render_from_master 48 "$ROOT_DIR/android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
render_from_master 72 "$ROOT_DIR/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
render_from_master 96 "$ROOT_DIR/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
render_from_master 144 "$ROOT_DIR/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
render_from_master 192 "$ROOT_DIR/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

render_from_master 20 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"
render_from_master 40 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"
render_from_master 60 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"
render_from_master 29 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"
render_from_master 58 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"
render_from_master 87 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"
render_from_master 40 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"
render_from_master 80 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"
render_from_master 120 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"
render_from_master 120 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"
render_from_master 180 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"
render_from_master 76 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"
render_from_master 152 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"
render_from_master 167 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"
render_from_master 1024 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"

render_from_master 16 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png"
render_from_master 32 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png"
render_from_master 64 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png"
render_from_master 128 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png"
render_from_master 256 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png"
render_from_master 512 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"
render_from_master 1024 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"

render_from_master 32 "$ROOT_DIR/web/favicon.png"
render_from_master 192 "$ROOT_DIR/web/icons/Icon-192.png"
render_from_master 512 "$ROOT_DIR/web/icons/Icon-512.png"
render_from_master 192 "$ROOT_DIR/web/icons/Icon-maskable-192.png"
render_from_master 512 "$ROOT_DIR/web/icons/Icon-maskable-512.png"

sips -z 256 256 -s format ico "$MASTER_PNG" --out "$ROOT_DIR/windows/runner/resources/app_icon.ico" >/dev/null

echo "Generated app icons from $SOURCE_SVG"

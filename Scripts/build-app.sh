#!/bin/bash
# 构建 Release 版本并打包为 Rescribium.app
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP_DIR="Rescribium.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp ".build/release/Rescribium" "$APP_DIR/Contents/MacOS/Rescribium"
cp "Config/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

echo "已生成 $APP_DIR"

#!/bin/bash
# WhitePoint をビルドして WhitePoint.app を作る
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/WhitePoint.app"

echo "🔨 ビルド中..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$DIR/Info.plist" "$APP/Contents/Info.plist"

swiftc -O "$DIR/Sources/main.swift" \
    -o "$APP/Contents/MacOS/WhitePoint" \
    -framework Cocoa -framework CoreGraphics -framework Carbon -framework ServiceManagement

echo "✅ 完成: $APP"
echo "   起動するには:  open \"$APP\""

#!/bin/bash
set -e

APP_NAME="QuickWindowSelector"
BUILD_DIR=".build/output"
DMG_NAME="${APP_NAME}.dmg"

echo "Building DMG for ${APP_NAME}..."
echo "================================"

cd "$(dirname "$0")"

echo "[1/5] Building app with swift..."
swift build -c release

echo "[2/5] Creating output directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "[3/5] Creating .app bundle structure..."
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

EXECUTABLE_PATH=".build/release/${APP_NAME}"
cp "$EXECUTABLE_PATH" "${APP_PATH}/Contents/MacOS/${APP_NAME}"

if [ -f "Resources/Info.plist" ]; then
    cp "Resources/Info.plist" "${APP_PATH}/Contents/Info.plist"
fi

if [ -d "Resources/Assets.xcassets" ]; then
    cp -r "Resources/Assets.xcassets" "${APP_PATH}/Contents/Resources/"
fi

echo "[4/5] Signing app..."
codesign --force --deep --sign "-" "$APP_PATH"

echo "[5/5] Creating DMG..."
hdiutil create \
    -srcfolder "$APP_PATH" \
    -volname "${APP_NAME}" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${BUILD_DIR}/${DMG_NAME}"

echo "Done!"
echo "================================"
echo "DMG created: $(pwd)/${BUILD_DIR}/${DMG_NAME}"

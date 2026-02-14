#!/bin/bash
set -e

APP_NAME="QuickWindowSelector"
BUILD_DIR=".build/output"
DMG_NAME="${APP_NAME}.dmg"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"

echo "Building DMG for ${APP_NAME}..."
echo "================================"

# Clean and build
echo "[1/4] Building app..."
cd "$(dirname "$0")"
swift build -c release

# Create output directory
echo "[2/4] Preparing output directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy app to output
cp -r ".build/release/${APP_NAME}.app" "$BUILD_DIR/"

# Sign the app (ad-hoc signing for local development)
echo "[3/5] Signing app..."
codesign --force --deep --sign "-" "$APP_PATH"

# Create DMG
echo "[4/5] Creating DMG..."

# Use create with folder source (macOS 13+)
hdiutil create \
    -srcfolder "${BUILD_DIR}/${APP_NAME}.app" \
    -volname "${APP_NAME}" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${BUILD_DIR}/${DMG_NAME}"

echo "[5/5] Done!"
echo "================================"
echo "DMG created: $(dirname "$0")/${DMG_NAME}"

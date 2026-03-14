#!/bin/bash
set -e

APP_NAME="Ascend"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"

echo "Building $APP_NAME..."

rm -rf "$BUILD_DIR"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

swiftc \
  "$SCRIPT_DIR/main.swift" \
  "$SCRIPT_DIR/AppState.swift" \
  "$SCRIPT_DIR/AppDelegate.swift" \
  "$SCRIPT_DIR/PopoverView.swift" \
  "$SCRIPT_DIR/SettingsView.swift" \
  "$SCRIPT_DIR/AlertOverlayView.swift" \
  "$SCRIPT_DIR/AboutView.swift" \
  -o "$CONTENTS/MacOS/$APP_NAME" \
  -framework Cocoa \
  -framework SwiftUI \
  -framework ServiceManagement \
  -O

cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/Info.plist"

# Ad-hoc sign so SMAppService can register a login item
codesign --sign - --force --deep "$APP_BUNDLE"

echo ""
echo "✓ Built & signed: $APP_BUNDLE"

# Create DMG
DMG_NAME="$APP_NAME.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
DMG_STAGING="$BUILD_DIR/dmg-staging"

echo "Creating $DMG_NAME..."

rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -r "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$DMG_STAGING"

echo ""
echo "✓ DMG:   $DMG_PATH"
echo ""
echo "Install: open \"$DMG_PATH\""

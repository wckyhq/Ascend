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

# Build .icns from PNG if needed
if [ ! -f "$SCRIPT_DIR/Ascend.icns" ] && [ -f "$SCRIPT_DIR/Ascend.png" ]; then
  echo "Generating Ascend.icns from Ascend.png..."
  ICONSET="$BUILD_DIR/Ascend.iconset"
  mkdir -p "$ICONSET"
  sips -z 16 16     "$SCRIPT_DIR/Ascend.png" --out "$ICONSET/icon_16x16.png"     > /dev/null
  sips -z 32 32     "$SCRIPT_DIR/Ascend.png" --out "$ICONSET/icon_16x16@2x.png"  > /dev/null
  sips -z 32 32     "$SCRIPT_DIR/Ascend.png" --out "$ICONSET/icon_32x32.png"     > /dev/null
  sips -z 64 64     "$SCRIPT_DIR/Ascend.png" --out "$ICONSET/icon_32x32@2x.png"  > /dev/null
  sips -z 128 128   "$SCRIPT_DIR/Ascend.png" --out "$ICONSET/icon_128x128.png"   > /dev/null
  sips -z 256 256   "$SCRIPT_DIR/Ascend.png" --out "$ICONSET/icon_128x128@2x.png"> /dev/null
  sips -z 256 256   "$SCRIPT_DIR/Ascend.png" --out "$ICONSET/icon_256x256.png"   > /dev/null
  sips -z 512 512   "$SCRIPT_DIR/Ascend.png" --out "$ICONSET/icon_256x256@2x.png"> /dev/null
  sips -z 512 512   "$SCRIPT_DIR/Ascend.png" --out "$ICONSET/icon_512x512.png"   > /dev/null
  cp "$SCRIPT_DIR/Ascend.png" "$ICONSET/icon_512x512@2x.png"
  iconutil -c icns "$ICONSET" -o "$SCRIPT_DIR/Ascend.icns"
  rm -rf "$ICONSET"
  echo "✓ Generated Ascend.icns"
fi

# Copy icon into app bundle
if [ -f "$SCRIPT_DIR/Ascend.icns" ]; then
  cp "$SCRIPT_DIR/Ascend.icns" "$CONTENTS/Resources/Ascend.icns"
fi

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

# Set DMG volume icon
if [ -f "$SCRIPT_DIR/Ascend.icns" ]; then
  cp "$SCRIPT_DIR/Ascend.icns" "$DMG_STAGING/.VolumeIcon.icns"
fi

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

# Apply volume icon flag (requires Xcode Command Line Tools)
if command -v SetFile &>/dev/null && [ -f "$SCRIPT_DIR/Ascend.icns" ]; then
  hdiutil attach "$DMG_PATH" -mountpoint /Volumes/"$APP_NAME" -quiet
  SetFile -a C /Volumes/"$APP_NAME"
  hdiutil detach /Volumes/"$APP_NAME" -quiet
fi

rm -rf "$DMG_STAGING"

echo ""
echo "✓ DMG:   $DMG_PATH"
echo ""
echo "Install: open \"$DMG_PATH\""

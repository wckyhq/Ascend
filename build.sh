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
  -O

cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/Info.plist"

echo ""
echo "✓ Built: $APP_BUNDLE"
echo ""
echo "Launch:   open \"$APP_BUNDLE\""
echo "Install:  mv \"$APP_BUNDLE\" /Applications/"

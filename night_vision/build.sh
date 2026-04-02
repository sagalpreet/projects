#!/bin/bash
set -e

# Simple script to build the Night Vision macOS app

APP_NAME="Night Vision"
EXECUTABLE_NAME="NightVision"
BUNDLE_ID="com.nightvision.app"
SWIFT_FILES="NightVisionApp.swift OverlayManager.swift ScreenAnalyzer.swift"

echo "Building $APP_NAME..."

# Create app bundle structure
mkdir -p "$APP_NAME.app/Contents/MacOS"

# Compile Swift files
# Linking standard macOS frameworks
swiftc -O -o "$APP_NAME.app/Contents/MacOS/$EXECUTABLE_NAME" \
    -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -target arm64-apple-macos14.0 \
    -framework Cocoa -framework SwiftUI -framework ScreenCaptureKit -framework VideoToolbox -framework CoreMedia \
    $SWIFT_FILES

# Copy Info.plist
cp Info.plist "$APP_NAME.app/Contents/Info.plist"

echo "Successfully built $APP_NAME.app"
echo "You can now run it using: open \"$APP_NAME.app\""

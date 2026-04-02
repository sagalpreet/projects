#!/bin/bash
set -e

# Simple script to build the Night Vision macOS app

APP_NAME="Night Vision"
EXECUTABLE_NAME="NightVision"
BUNDLE_ID="com.nightvision.app"
SWIFT_FILES="NightVisionApp.swift OverlayManager.swift ScreenAnalyzer.swift"

echo "Building $APP_NAME..."

# Kill any running instance
pkill -f "Night Vision" 2>/dev/null || true

# Create app bundle structure
mkdir -p "$APP_NAME.app/Contents/MacOS"

# Compile Swift files
swiftc -O -o "$APP_NAME.app/Contents/MacOS/$EXECUTABLE_NAME" \
    -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -target arm64-apple-macos14.0 \
    -framework Cocoa -framework SwiftUI -framework ScreenCaptureKit -framework VideoToolbox -framework CoreMedia -framework CoreGraphics \
    $SWIFT_FILES

# Copy Info.plist
cp Info.plist "$APP_NAME.app/Contents/Info.plist"

# Copy Resources (App Icon)
mkdir -p "$APP_NAME.app/Contents/Resources"
if [ -f "NightVision.icns" ]; then
    cp NightVision.icns "$APP_NAME.app/Contents/Resources/"
fi

# Ad-hoc sign the app with entitlements
echo "Signing app with entitlements..."
codesign -s - --force --deep --entitlements "NightVision.entitlements" "$APP_NAME.app"

# Reset TCC permissions for this bundle ID so new signature is accepted
echo "Resetting screen capture permissions for fresh signature..."
tccutil reset ScreenCapture "$BUNDLE_ID" 2>/dev/null || true

echo "Successfully built $APP_NAME.app"
echo "Copy to /Applications and launch. Grant Screen Recording permission when prompted."

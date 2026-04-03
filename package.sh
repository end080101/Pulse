#!/bin/bash

set -euo pipefail

APP_NAME="Pulse"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
DMG_NAME="${APP_NAME}.dmg"

echo "Step 1: Cleaning previous builds..."
rm -rf "${APP_BUNDLE}"
rm -f "${DMG_NAME}"
rm -rf "dmg_temp"

echo "Step 2: Building binaries..."
swift build -c release
swiftc ThermalHelper.swift -o ThermalHelper

echo "Step 3: Creating bundle structure..."
mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

echo "Step 4: Copying files..."
cp .build/release/Pulse "${MACOS}/${APP_NAME}"
cp ThermalHelper "${RESOURCES}/"
cp Info.plist "${CONTENTS}/"
cp -R .build/release/Pulse_Pulse.bundle "${RESOURCES}/"

echo "Step 5: Setting permissions..."
chmod +x "${MACOS}/${APP_NAME}"
chmod +x "${RESOURCES}/ThermalHelper"

echo "Step 6: Signing (Ad-hoc)..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Step 7: Creating DMG..."
mkdir -p "dmg_temp"
cp -R "${APP_BUNDLE}" "dmg_temp/"
ln -s /Applications "dmg_temp/Applications"

hdiutil create -volname "${APP_NAME} Installer" -srcfolder "dmg_temp" -ov -format UDZO "${DMG_NAME}"

rm -rf "dmg_temp"

echo "------------------------------------------------"
echo "Success! ${DMG_NAME} has been created."
echo "Path: $(pwd)/${DMG_NAME}"
echo "------------------------------------------------"

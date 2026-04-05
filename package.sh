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

# Add static icon from GIF (white rounded bg, black rabbit, 80% content)
RESOURCES_DIR="${RESOURCES}" python3 - <<'PYEOF'
from PIL import Image, ImageDraw, ImageSequence
import os, shutil

gif_path = "Sources/Pulse/Resources/icon.gif"
iconset_dir = "/tmp/Pulse.iconset"
os.makedirs(iconset_dir, exist_ok=True)

img = Image.open(gif_path).convert("RGBA")
frames = list(ImageSequence.Iterator(img))
mid = frames[len(frames) // 2]

size = 1024
canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
radius = int(size * 0.22)
draw = ImageDraw.Draw(canvas)
draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=(255, 255, 255, 255))

rabbit_size = int(size * 0.80)
rabbit = mid.resize((rabbit_size, rabbit_size), Image.LANCZOS).convert("RGBA")

px = rabbit.load()
for y in range(rabbit.size[1]):
    for x in range(rabbit.size[0]):
        r, g, b, a = px[x, y]
        if a > 0 and not (r > 200 and g > 200 and b > 200):
            px[x, y] = (0, 0, 0, a)

offset = ((size - rabbit.size[0]) // 2, (size - rabbit.size[1]) // 2)
canvas.paste(rabbit, offset, rabbit)

for s in [16, 32, 64, 128, 256, 512]:
    resized = canvas.resize((s, s), Image.LANCZOS)
    resized.save(f"{iconset_dir}/icon_{s}x{s}.png")
    if s <= 256:
        resized_2x = canvas.resize((s * 2, s * 2), Image.LANCZOS)
        resized_2x.save(f"{iconset_dir}/icon_{s}x{s}@2x.png")

os.system("iconutil -c icns /tmp/Pulse.iconset -o Pulse.icns")
res_dir = os.environ["RESOURCES_DIR"]
shutil.copy("Pulse.icns", f"{res_dir}/Pulse.icns")
PYEOF

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

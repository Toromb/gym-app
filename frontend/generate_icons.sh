#!/bin/bash

SOURCE="frontend/assets/icon.png"
DEST="frontend/ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Ensure destination exists
mkdir -p "$DEST"

# Function to resize
resize() {
    SIZE=$1
    NAME=$2
    sips -z $SIZE $SIZE "$SOURCE" --out "$DEST/$NAME"
}

echo "Generating icons..."

# iPhone
resize 40 "Icon-App-20x20@2x.png"
resize 60 "Icon-App-20x20@3x.png"
resize 29 "Icon-App-29x29@1x.png"
resize 58 "Icon-App-29x29@2x.png"
resize 87 "Icon-App-29x29@3x.png"
resize 80 "Icon-App-40x40@2x.png"
resize 120 "Icon-App-40x40@3x.png"
resize 120 "Icon-App-60x60@2x.png"
resize 180 "Icon-App-60x60@3x.png"

# iPad
resize 20 "Icon-App-20x20@1x.png"
resize 40 "Icon-App-40x40@1x.png"
resize 76 "Icon-App-76x76@1x.png"
resize 152 "Icon-App-76x76@2x.png"
resize 167 "Icon-App-83.5x83.5@2x.png"

# App Store
resize 1024 "Icon-App-1024x1024@1x.png"

echo "Icons generated successfully!"

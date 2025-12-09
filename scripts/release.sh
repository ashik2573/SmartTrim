#!/bin/bash
set -euo pipefail

# Configuration
APP_NAME="SmartTrim"
SCHEME="SmartTrim"
TEAM_ID="435YLH52L5"
SIGNING_IDENTITY="Developer ID Application: Gordon Mickel ($TEAM_ID)"
NOTARYTOOL_PROFILE="notarytool-profile"

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
APP_PATH="$EXPORT_PATH/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

# Read version from project.yml
VERSION=$(grep 'MARKETING_VERSION:' "$PROJECT_DIR/project.yml" | sed 's/.*: *"\(.*\)"/\1/')
BUILD=$(grep 'CURRENT_PROJECT_VERSION:' "$PROJECT_DIR/project.yml" | sed 's/.*: *"\(.*\)"/\1/')

echo "=== Building $APP_NAME v$VERSION (build $BUILD) ==="

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cd "$PROJECT_DIR"

# Generate Xcode project
echo ">>> Generating Xcode project..."
xcodegen

# Build universal binary (arm64 + x86_64)
echo ">>> Building universal binary..."
xcodebuild -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE="Manual" \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime" \
    archive

# Export archive
echo ">>> Exporting archive..."
cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"

# Verify signing
echo ">>> Verifying code signature..."
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | head -20
codesign --verify --deep --strict "$APP_PATH"
echo "✓ Code signature valid"

# Notarize
echo ">>> Submitting for notarization..."
ditto -c -k --keepParent "$APP_PATH" "$BUILD_DIR/$APP_NAME.zip"

xcrun notarytool submit "$BUILD_DIR/$APP_NAME.zip" \
    --keychain-profile "$NOTARYTOOL_PROFILE" \
    --wait

# Staple
echo ">>> Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

# Verify notarization
echo ">>> Verifying notarization..."
spctl --assess --type exec -vv "$APP_PATH"
echo "✓ Notarization valid"

# Create DMG
echo ">>> Creating DMG..."
rm -f "$DMG_PATH"

# Create temp folder for DMG contents
DMG_TEMP="$BUILD_DIR/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "$APP_PATH" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_TEMP"

# Notarize DMG
echo ">>> Notarizing DMG..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARYTOOL_PROFILE" \
    --wait

xcrun stapler staple "$DMG_PATH"

# Rename with version
FINAL_DMG="$BUILD_DIR/${APP_NAME}-${VERSION}.dmg"
mv "$DMG_PATH" "$FINAL_DMG"

# Final output
echo ""
echo "=== Build Complete ==="
echo "DMG: $FINAL_DMG"
echo "Size: $(du -h "$FINAL_DMG" | cut -f1)"
echo ""
echo "To create GitHub release:"
echo "  gh release create v$VERSION '$FINAL_DMG' --title 'v$VERSION' --generate-notes"

# Development

## Prerequisites

- macOS 14.0+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build

```bash
xcodegen
xcodebuild -scheme SmartTrim -configuration Debug
```

## Test

```bash
xcodebuild -scheme SmartTrim -destination 'platform=macOS' test
```

## Release

Requires Apple Developer account with:
- Developer ID Application certificate
- Notarytool credentials stored in keychain

### One-time setup

```bash
# Store notarization credentials
xcrun notarytool store-credentials "notarytool-profile" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

### Build signed release

```bash
./scripts/release.sh 1.0.0
```

This will:
1. Build universal binary (arm64 + x86_64)
2. Sign with Developer ID + hardened runtime
3. Notarize with Apple
4. Staple notarization ticket
5. Create DMG
6. Output `gh release` command

### Publish to GitHub

```bash
gh release create v1.0.0 'build/SmartTrim.dmg' --title 'v1.0.0' --notes 'Initial release'
```

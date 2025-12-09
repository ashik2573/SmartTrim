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

## Version

Version is stored in `project.yml`:
- `MARKETING_VERSION` — User-facing version (1.0.0)
- `CURRENT_PROJECT_VERSION` — Build number (1, 2, 3...)

### Bump version

```bash
./scripts/bump.sh patch   # 1.0.0 → 1.0.1
./scripts/bump.sh minor   # 1.0.0 → 1.1.0
./scripts/bump.sh major   # 1.0.0 → 2.0.0
```

Then commit:
```bash
git add project.yml
git commit -m "Bump version to X.Y.Z"
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
./scripts/release.sh
```

Reads version from `project.yml` and:
1. Builds universal binary (arm64 + x86_64)
2. Signs with Developer ID + hardened runtime
3. Notarizes with Apple
4. Staples notarization ticket
5. Creates versioned DMG (`SmartTrim-X.Y.Z.dmg`)

### Publish to GitHub

```bash
gh release create v1.0.0 'build/SmartTrim-1.0.0.dmg' --title 'v1.0.0' --generate-notes
```

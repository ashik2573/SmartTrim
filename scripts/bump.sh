#!/bin/bash
set -euo pipefail

PROJECT_FILE="$(dirname "$0")/../project.yml"

# Get current version
CURRENT_VERSION=$(grep 'MARKETING_VERSION:' "$PROJECT_FILE" | sed 's/.*: *"\(.*\)"/\1/')
CURRENT_BUILD=$(grep 'CURRENT_PROJECT_VERSION:' "$PROJECT_FILE" | sed 's/.*: *"\(.*\)"/\1/')

echo "Current: v$CURRENT_VERSION (build $CURRENT_BUILD)"

# Parse args
BUMP_TYPE="${1:-patch}"

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Usage: $0 [major|minor|patch]"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
NEW_BUILD=$((CURRENT_BUILD + 1))

# Update project.yml
sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$NEW_VERSION\"/" "$PROJECT_FILE"
sed -i '' "s/CURRENT_PROJECT_VERSION: \".*\"/CURRENT_PROJECT_VERSION: \"$NEW_BUILD\"/" "$PROJECT_FILE"

echo "Updated: v$NEW_VERSION (build $NEW_BUILD)"
echo ""
echo "Next steps:"
echo "  git add project.yml"
echo "  git commit -m 'Bump version to $NEW_VERSION'"
echo "  ./scripts/release.sh"

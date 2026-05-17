#!/usr/bin/env bash
#
# Archive + export sonicc for App Store Connect upload.
#
# Usage:
#   APPLE_TEAM_ID=ABCD123456 ./release/archive.sh
#
# Produces:
#   build/Sonicc.xcarchive — the archive (signed)
#   build/export/Sonicc.ipa — App Store-bound IPA
#   build/export/DistributionSummary.plist
#   build/export/ExportOptions.plist
#
# Next step (manual):
#   xcrun altool --upload-app -f build/export/Sonicc.ipa \
#     -t ios -u <APPLE_ID> -p <APP_SPECIFIC_PASSWORD>
#
# Or use Xcode → Organizer → Distribute to upload via UI.

set -euo pipefail

if [[ -z "${APPLE_TEAM_ID:-}" ]]; then
    echo "ERROR: set APPLE_TEAM_ID=<your team id> before running."
    echo "       Get it from https://developer.apple.com/account → Membership Details."
    exit 1
fi

cd "$(dirname "$0")/.."   # repo root
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Make sure project.yml has the team id (xcodegen reads it from there).
sed -i.bak "s|DEVELOPMENT_TEAM: \"\"|DEVELOPMENT_TEAM: \"$APPLE_TEAM_ID\"|" ios/project.yml
xcodegen generate --spec ios/project.yml

ARCHIVE_PATH="build/Sonicc.xcarchive"
EXPORT_PATH="build/export"

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
mkdir -p build

echo "==> Archiving (Release)..."
xcodebuild \
    -project ios/Sonicc.xcodeproj \
    -scheme Sonicc \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    archive

echo "==> Exporting for App Store Connect..."
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist release/ExportOptions.plist \
    -allowProvisioningUpdates

# Restore project.yml (don't commit team id)
mv ios/project.yml.bak ios/project.yml

echo "==> Done."
echo "    Archive: $ARCHIVE_PATH"
echo "    IPA:     $EXPORT_PATH/Sonicc.ipa"
echo ""
echo "Upload with one of:"
echo "  1. Xcode → Organizer → select archive → Distribute App"
echo "  2. xcrun altool --upload-app -f $EXPORT_PATH/Sonicc.ipa -t ios -u <APPLE_ID> -p <APP_SPECIFIC_PWD>"
echo "  3. xcrun notarytool / Transporter app"

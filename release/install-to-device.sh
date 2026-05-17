#!/usr/bin/env bash
#
# Install sonicc onto a connected physical device (iPhone or iPad).
#
# Usage:
#   ./release/install-to-device.sh                # auto-pick first available device
#   ./release/install-to-device.sh <DEVICE_UDID>  # specific device
#
# Prerequisites:
#   1. Open Xcode at least once. Sign in to your Apple ID under
#      Xcode → Settings → Accounts. A free Apple ID gives you a
#      7-day "personal team" provisioning profile, which is enough
#      to install on your own devices.
#   2. Connect the device via cable, unlock it, tap Trust this Computer.
#   3. xcrun devicectl list devices  → should show the device as "available".

set -euo pipefail

cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodegen generate --spec ios/project.yml > /dev/null 2>&1

PROJECT=ios/Sonicc.xcodeproj
SCHEME=Sonicc
BUNDLE_ID=studio.kami.sonicc

# Pick device (1st arg or first available)
DEVICE_UDID="${1:-$(xcrun devicectl list devices 2>/dev/null | awk '/available \(paired\)/ {print $3; exit}')}"

if [[ -z "$DEVICE_UDID" ]]; then
    echo "ERROR: no available device. Connect via cable + unlock + Trust this Computer."
    xcrun devicectl list devices 2>&1 | tail -10
    exit 1
fi

echo "==> Installing onto device: $DEVICE_UDID"

BUILD_DIR=build/device
rm -rf "$BUILD_DIR"

# Xcode-managed automatic signing via personal team. This works without
# a paid developer account — the profile expires after 7 days.
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "id=$DEVICE_UDID" \
    -derivedDataPath "$BUILD_DIR" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    install

echo ""
echo "==> Done. Launch the app from the device's home screen."
echo "    If the app crashes on launch with 'Untrusted Developer', go to:"
echo "    Settings → General → VPN & Device Management → trust your Apple ID."

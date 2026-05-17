#!/usr/bin/env bash
#
# Capture marketing screenshots at the sizes App Store Connect requires.
#
# 6.9" iPhone   → iPhone 17 Pro Max sim (1320 × 2868)
# 6.7" iPhone   → iPhone 17 Pro sim     (1290 × 2796)
# 13" iPad Pro  → iPad Pro 13" M5 sim   (2064 × 2752)
#
# Drops PNGs into release/marketing/. Run the app, navigate to each
# scene, hit ENTER to capture. The script doesn't try to scrape — it
# just makes the capture loop fast.

set -euo pipefail

cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

OUT=release/marketing
mkdir -p "$OUT"

# Detect booted sims, fall back to the canonical ones if not booted.
IPHONE=$(xcrun simctl list devices booted 2>/dev/null | grep -oE '[0-9A-F-]{36}' | head -1 || echo "")
IPAD=$(xcrun simctl list devices booted 2>/dev/null   | grep -oE '[0-9A-F-]{36}' | sed -n '2p' || echo "")

if [[ -z "$IPHONE" || -z "$IPAD" ]]; then
    echo "==> Booting sims..."
    IPHONE=$(xcrun simctl list devices "iOS 26.5" 2>/dev/null | grep "iPhone 17 Pro Max" | grep -oE '[0-9A-F-]{36}' | head -1)
    IPAD=$(xcrun simctl list devices "iOS 26.5"   2>/dev/null | grep "iPad Pro 13-inch" | grep -oE '[0-9A-F-]{36}' | head -1)
    [[ -n "$IPHONE" ]] && xcrun simctl boot "$IPHONE" 2>/dev/null || true
    [[ -n "$IPAD"   ]] && xcrun simctl boot "$IPAD"   2>/dev/null || true
fi

capture() {
    local label="$1"
    local udid="$2"
    local out="$OUT/$label.png"
    echo ""
    echo "==> Navigate to scene: $label"
    read -r -p "    Press ENTER to capture (device $udid)... "
    xcrun simctl io "$udid" screenshot "$out"
    echo "    Saved $out"
}

if [[ -n "$IPHONE" ]]; then
    echo "iPhone: $IPHONE"
    capture "01-iphone-keys"    "$IPHONE"
    capture "02-iphone-pattern" "$IPHONE"
    capture "03-iphone-mic"     "$IPHONE"
    capture "04-iphone-drums"   "$IPHONE"
    capture "05-iphone-settings" "$IPHONE"
fi

if [[ -n "$IPAD" ]]; then
    echo "iPad: $IPAD"
    capture "10-ipad-keys"    "$IPAD"
    capture "11-ipad-pattern" "$IPAD"
    capture "12-ipad-mic"     "$IPAD"
    capture "13-ipad-drums"   "$IPAD"
    capture "14-ipad-settings" "$IPAD"
fi

echo ""
echo "==> Done. Marketing screenshots in $OUT"
echo "    Upload these to App Store Connect → Distribution → iOS Previews and Screenshots"

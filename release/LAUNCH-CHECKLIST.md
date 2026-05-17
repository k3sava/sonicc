# sonicc — launch checklist

Tomorrow. Step by step. No surprises.

---

## 1. Apple Developer enrollment (today)

- [ ] https://developer.apple.com/programs/enroll/ → $99/year
- [ ] After enrollment, **Team ID** appears at https://developer.apple.com/account → Membership Details. Looks like `ABCD123456` (10 alphanumeric).

## 2. App Store Connect — create the app record

- [ ] https://appstoreconnect.apple.com → My Apps → "+" → New App
- [ ] Platform: iOS
- [ ] Name: `sonicc`
- [ ] Primary language: English (U.S.)
- [ ] Bundle ID: `studio.kami.sonicc` (create if it doesn't exist — Identifiers tab in dev portal)
- [ ] SKU: `sonicc-ios-1.0`
- [ ] User Access: Full Access

## 3. Build and upload

```bash
# from /Users/k3sava/projects/sonicc
APPLE_TEAM_ID=YOURTEAMID ./release/archive.sh
```

This produces `build/export/Sonicc.ipa`. Three ways to upload:

- **Easiest**: Xcode → Open Developer Tool → Transporter → drag the .ipa
- **CLI**: `xcrun altool --upload-app -f build/export/Sonicc.ipa -t ios -u <APPLE_ID> -p <APP_SPECIFIC_PASSWORD>`
- **Xcode Organizer**: Window → Organizer → Archives → select → Distribute App

App-specific password: https://appleid.apple.com → Sign-In and Security → App-Specific Passwords

Wait ~10 minutes after upload for App Store Connect to process the build.

## 4. Set up the In-App Purchase

- [ ] App Store Connect → My Apps → Sonicc → Monetization → In-App Purchases → "+"
- [ ] Non-Consumable
- [ ] Reference Name: `Sonicc Lifetime`
- [ ] Product ID: `studio.kami.sonicc.lifetime` (must match exactly)
- [ ] Pricing: $7.99 (Tier 8)
- [ ] Family Sharing: enabled
- [ ] Display Name + Description: copy from `app-store-metadata.md`
- [ ] Upload a 1024x1024 review screenshot (the paywall screen)
- [ ] Cleared for Sale: ✓
- [ ] **Submit with App** (don't submit separately — submit alongside the binary)

## 5. App Privacy nutrition labels

- [ ] App Store Connect → My Apps → Sonicc → App Privacy → Get Started
- [ ] "Do you or your third-party partners collect data from this app?" → **No**
- [ ] Save

(Yes, the mic recording stays on the device — that's not "collection" in App Store Privacy terms because nothing leaves the device.)

## 6. Age rating questionnaire

- [ ] App Store Connect → My Apps → Sonicc → Age Rating → Edit
- [ ] All categories: None → final rating 4+

## 7. Marketing assets

- [ ] App icon (1024x1024) — auto-pulled from the archive, already in the binary
- [ ] Screenshots — run `./release/capture-screenshots.sh` after navigating to each scene
- [ ] Required sizes: 6.9" iPhone (1320×2868), 6.7" iPhone (1290×2796), 13" iPad (2064×2752). Minimum 3 each.
- [ ] App preview video (optional but recommended) — record from sim with QuickTime → save as .mov

## 8. App information

Paste from `app-store-metadata.md`:

- [ ] Name, Subtitle, Promotional Text
- [ ] Description (4000 char)
- [ ] Keywords
- [ ] What's New (release notes)
- [ ] Marketing URL, Support URL, Privacy Policy URL, Copyright

## 9. Pricing

- [ ] App Store Connect → My Apps → Sonicc → Pricing and Availability
- [ ] Price: **Free** (you're using IAP for the unlock, not a paid app)
- [ ] Availability: All territories

## 10. Submit for review

- [ ] App Store Connect → My Apps → Sonicc → 1.0 Prepare for Submission
- [ ] App Review Information: name, email, phone, app review notes (copy from `app-store-metadata.md`)
- [ ] Demo account: leave blank (no account needed)
- [ ] Add for Review → Submit to App Review
- [ ] Typical approval time in 2026: 24–48 hours

## 11. After approval

- [ ] Auto-release on approval (default) OR manual release
- [ ] If manual, ship from App Store Connect → Pricing & Availability → release
- [ ] Monitor App Store Connect → Analytics for first-day data
- [ ] Optional: schedule a phased release (App Store Connect → 1.0 Prepare → Phased Release for Automatic Updates)

---

## Common pitfalls

| Mistake | Fix |
|---|---|
| IAP "Missing Metadata" in App Store Connect | Submit the IAP with the app, not before |
| "Bundle ID already exists" | The identifier was claimed in dev portal but not connected — go to Identifiers tab and verify capability matches |
| Archive fails with signing error | Run `xcodegen generate` after the script sets DEVELOPMENT_TEAM |
| Review rejects "missing Restore Purchases" | It's already wired in Settings; respond with a screenshot |
| Camera/Mic permission rejected | Permission strings in Info.plist are present; resubmit if rejected |
| Privacy nutrition labels fail | All data stays on device → no collection → answer "No" |

## Reference

- Apple Developer Program enroll: https://developer.apple.com/programs/enroll/
- App Store Connect: https://appstoreconnect.apple.com
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- StoreKit 2 docs: https://developer.apple.com/storekit/
- App Store screenshot sizes: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications

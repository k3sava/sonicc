# sonicc — App Store Connect metadata

Paste each field into App Store Connect → My Apps → Sonicc → Distribution.

---

## Basic info

| Field | Value |
|---|---|
| Name | sonicc |
| Subtitle (30 char) | A pocket instrument |
| Bundle ID | studio.kami.sonicc |
| SKU | sonicc-ios-1.0 |
| Primary language | English (U.S.) |
| Primary category | Music |
| Secondary category | Entertainment |
| Age rating | 4+ |
| Content rights | Does not contain third-party content |
| Price tier | Free (in-app purchase only) |
| Distribution | iPhone, iPad |

## Promotional text (170 char)

> Now with pattern chain, triplet subdivisions, WAV export, and a built-in chord recognizer that names every chord you play.

## Description (4000 char)

```
sonicc is a real instrument built for your phone and your iPad.

Five sound surfaces, one tap apart:

KEYS
Velocity-sensitive piano with a real pitch-bend wheel and a sustain pedal. Pick a scale and in-key notes glow softly so you can play without thinking. Hold three or four fingers and the chord recognizer names what you're playing — Cmaj7, Dm7♭5, sus4 — live as you play it.

DRUMS
Eight sound-designed kit elements with hit-pulse haptics. Tap, lay down a beat, hand off to the sequencer.

PATTERN
A real step sequencer. 8, 16, 32, or 64 steps. Subdivisions from 1/8 to 1/16-triplet. Swing. Auto-save. Per-row pitches so every cell is a melody, not just an on/off. Four song slots (A, B, C, D) chain into full arrangements. Bounce to M4A for sharing or WAV for Logic and Ableton.

SAMPLER
Record any sound, slice it, drop it onto a pad, loop it.

MIC
Record vocals or anything in the room. Preview, save, share, or send to the sampler.

WHY YOU'LL LIKE IT
— No subscription. Seven-day trial, then a one-time payment. Yours forever.
— Built for VoiceOver. Every control labeled, every value spoken.
— Honors Dynamic Type, Reduce Motion, and your system haptic preference.
— Universal app. iPhone and iPad, portrait and landscape.
— Background audio, MIDI in, low-latency AVAudioEngine.
— Auto-save on every change. You can't lose a pattern.

Made by kami studios.
```

## Keywords (100 char, comma-separated)

```
synth,piano,sequencer,drum machine,music maker,beat maker,chord,MIDI,recording,sampler
```

## What's New in This Version (release notes — 4000 char)

### Version 1.0 (build 1)

```
First release.

Five performance surfaces — Keys, Drums, Pattern, Sampler, Mic — with a
shared sound engine, MIDI in, auto-save, and clean export to M4A or WAV.

Highlights:
• Velocity-sensitive piano with scale picker, sustain, and a real
  pitch-bend wheel
• Live chord recognition (Cmaj7, Dm7♭5, sus4) right above the keyboard
• 4 song slots with chain mode
• Triplet and dotted subdivisions
• WAV export for DAWs
• Auto-save — your pattern survives every launch

Welcome.
```

## URLs

| Field | Value |
|---|---|
| Marketing URL | https://kami.studio/sonicc |
| Support URL | https://kami.studio/sonicc/support |
| Privacy Policy URL | https://kami.studio/privacy |
| Copyright | © 2026 kami studios |

If the URLs don't resolve yet, point them to a single placeholder page at
https://kami.studio so App Store Review doesn't reject. The links can be
updated after the first build is approved.

---

## App Privacy nutrition labels

In App Store Connect → App Privacy → Get Started:

### Does this app collect data from this app? **No**

(The app uses the microphone and stores data locally only. Nothing is
transmitted to any server, including ours.)

### Data Used to Track You: **None**
### Data Linked to You: **None**
### Data Not Linked to You: **None**

### Privacy Practices Disclosures
- App Functionality
  - Audio data (for recording / playback only, **stays on device**)
  - Microphone (for recording feature)

---

## In-App Purchase (App Store Connect → In-App Purchases → +)

| Field | Value |
|---|---|
| Reference Name | Sonicc Lifetime |
| Product ID | studio.kami.sonicc.lifetime |
| Type | Non-Consumable |
| Cleared for Sale | Yes |
| Price Tier | $7.99 (Tier 8) |
| Family Sharing | Enable |

### Display Name
```
Sonicc Lifetime
```

### Description
```
Unlock sonicc forever. One-time payment, no subscription. Available on
every device signed in to your Apple ID. Family Sharing supported.
```

### Review information
- Screenshot: take from app's Settings → tap "Unlock sonicc" to open the
  paywall. Upload a 1290×2796 PNG.
- Review notes: "Non-consumable IAP. Unlocks all features permanently
  after the in-app 7-day trial. Test via the in-app paywall."

---

## Marketing screenshots required by App Store Connect

| Device | Size | Count |
|---|---|---|
| 6.9" iPhone (iPhone 17 Pro Max) | 1320 × 2868 | 3–10 |
| 6.7" iPhone | 1290 × 2796 | 3–10 |
| 13" iPad Pro M5 | 2064 × 2752 | 3–10 |

The `release/capture-screenshots.sh` script generates these
automatically from the simulator and saves them to `release/marketing/`.

Recommended screenshots:
1. Keys mode with a held chord (Cmaj7 visible in the chord readout)
2. Pattern mode with a few cells lit + chain slots
3. Mic mode mid-record (red recording state)
4. Drums mode with hit pulse
5. Settings sheet showing the trial state

---

## App Review notes

```
Sonicc is a music-making tool with five performance surfaces. All
features are available during the 7-day trial. After the trial, the
in-app purchase "Sonicc Lifetime" unlocks the app permanently.

For review:
- Microphone permission gates only the Mic recording surface
- IAP product: studio.kami.sonicc.lifetime ($7.99 non-consumable)
- Restore Purchases is in Settings (gear icon in top-right)
- No login or account required
- No data is transmitted off-device

Test account: not needed. The trial begins on first launch.
```

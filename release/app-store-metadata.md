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

```
Pattern chains, triplet subdivisions, WAV export, and a chord recognizer that names what you play as you play it.
```

## Description (4000 char)

```
sonicc is a small synthesizer that sits in your pocket.

There are five surfaces. You move between them with a tap.

KEYS
A piano with weight. Press near the top of a key for a soft note. Press near the bottom for a louder one. Pick a scale and the notes that belong glow softly so you don't have to think about which to play. Hold three or four fingers at once and the chord name shows up above the keys, in real time. Cmaj7. Dm7♭5. Gsus4. Pitch bend wheel. Sustain pedal. Velocity. The way a piano should feel.

DRUMS
Eight kit pieces with a haptic pulse on every hit. Kick. Snare. Hi-hat. Clap. Tom. Crash. Perc. Cowbell. Tap a few, hand the loop to the sequencer.

PATTERN
A step sequencer that remembers everything. Eight, sixteen, thirty-two, or sixty-four steps. Subdivisions from straight eighths down to sixteenth triplets. Swing. Every row plays its own pitch, so the grid is a melody, not a metronome. Four song slots, A through D, that chain into a full arrangement when you turn chain mode on. Bounce to M4A for sharing. Bounce to WAV for Logic or Ableton.

SAMPLER
Record a sound. Trim it. Drop it onto one of four pads. Loop it. Play it.

MIC
Catch your voice or anything in the room. Preview. Save. Hand it to the sampler.

Other things you might care about:

— No subscription. Seven days free. One payment after that. Yours.
— Built with VoiceOver in mind. Every control has a label, every value gets read aloud.
— Honors Dynamic Type. Honors Reduce Motion. Honors your haptic preference.
— Universal. iPhone and iPad. Portrait and landscape.
— Plays in the background. Accepts MIDI. Low latency through AVAudioEngine.
— Saves your pattern on every change. You can't lose work.

Made by kami studios.
```

## Keywords (100 char, comma-separated)

```
synth,piano,sequencer,drum machine,music maker,beat maker,chord,MIDI,recording,sampler
```

## What's New in This Version

### Version 1.0 (build 1)

```
First release.

Five surfaces with one shared sound engine. MIDI in. Auto-save. M4A or WAV export.

A few things worth knowing about this build:
• Touch position on a key sets velocity, so the same finger gets soft and loud notes
• Pick a key and a scale and stay in it without thinking
• The chord above the keyboard names itself as you play
• Pattern A through D chain into a song when you turn chain on
• Triplet subdivisions for grooves the grid usually can't hold

Welcome.
```

## URLs

| Field | Value |
|---|---|
| Marketing URL | https://kami.studio/sonicc |
| Support URL | https://kami.studio/sonicc/support |
| Privacy Policy URL | https://kami.studio/privacy |
| Copyright | © 2026 kami studios |

If the URLs don't resolve yet, point them at a placeholder at
https://kami.studio so App Store Review doesn't reject. The links can be
updated after the first build is approved.

---

## App Privacy nutrition labels

In App Store Connect → App Privacy → Get Started:

### Does this app collect data from this app? **No**

The mic recording stays on the device. Nothing is transmitted to any server, including ours.

### Data Used to Track You: **None**
### Data Linked to You: **None**
### Data Not Linked to You: **None**

### Privacy Practices Disclosures
- App Functionality
  - Audio data (recording / playback only, stays on device)
  - Microphone (recording feature only)

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
Keep using sonicc after the seven-day trial. One payment. No subscription.
Carries to every device signed in to your Apple ID. Family Sharing works.
```

### Review information
- Screenshot: open Settings inside the app, tap "Unlock sonicc" to reach the purchase sheet. Upload a 1290×2796 PNG.
- Review notes: "Non-consumable. Unlocks all features after the in-app seven-day trial. Test from the paywall in Settings."

---

## Marketing screenshots App Store Connect requires

| Device | Size | Count |
|---|---|---|
| 6.9" iPhone (iPhone 17 Pro Max) | 1320 × 2868 | 3–10 |
| 6.7" iPhone | 1290 × 2796 | 3–10 |
| 13" iPad Pro M5 | 2064 × 2752 | 3–10 |

The `release/capture-screenshots.sh` script captures these from the sim.

Suggested scenes:
1. Keys with a held chord (Cmaj7 visible above the keys)
2. Pattern with a few cells lit and the slot row visible
3. Mic mid-record (the red recording state)
4. Drums with a hit pulse
5. Settings showing the trial state

---

## App Review notes

```
sonicc is a music-making tool with five performance surfaces. Every feature
is open during the seven-day trial. After the trial, the in-app purchase
"Sonicc Lifetime" keeps the app available permanently.

For review:
- Microphone permission only gates the Mic surface
- IAP: studio.kami.sonicc.lifetime ($7.99, non-consumable, family-shareable)
- Restore Purchases lives in Settings (gear icon at top right)
- No login or account required
- No data leaves the device

Test account: not needed. The trial begins on first launch.
```

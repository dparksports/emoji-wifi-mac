<div align="center">

<img src="docs/app-icon.png" alt="EmojiWifi app icon" width="128"/>

# EmojiWifi

**WiFi names & passwords made entirely of emoji** 📶✨

Generate, scan, and join — in one native macOS app.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black?logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/Swift-SwiftUI-F05138?logo=swift&logoColor=white)
![Release](https://img.shields.io/github/v/release/dparksports/emoji-wifi-mac)
![License](https://img.shields.io/badge/License-Apache%202.0-blue)

<img src="docs/hero.svg" alt="EmojiWifi hero — an emoji SSID 🍕🚀🌌 next to a scannable QR code" width="880"/>

</div>

## What is EmojiWifi?

EmojiWifi turns your WiFi network into something worth reading. Instead of
`FritzBox4711_5GHz`, your guests see `🍕🚀🌌` or `🎮👾🤖` — the app generates an
emoji-only network name and a strong random password, renders a scannable QR
code, and can even join the network for you. It also reads WiFi QR codes back:
point your Mac's camera at one, or drop in an image file, and EmojiWifi parses
it into SSID and password instantly.

## ✨ Features

<img src="docs/features.svg" alt="Feature grid: emoji name generator, password generator, instant QR codes, two ways to scan, auto join, persistent history" width="880"/>

- **Three name styles** — curated emoji combinations (70 built in), single
  emojis (a 533-emoji dataset with descriptions), or random-length strings.
  Browse the full combination library in a searchable grid.
- **Tunable passwords** — 8–63 characters with independent A-Z / a-z / 0-9 /
  `!@#` toggles, regenerated live as you adjust.
- **QR codes, both directions** — every generated network gets a WPA QR code
  (error-correction level M), and the scanner accepts camera frames or
  imported images via Apple's on-device QR detection.
- **Auto Join** — one click runs `networksetup` to connect your Mac to the
  generated or scanned network.
- **Persistent history** — every generated, scanned, or imported network is
  stored locally as JSON (`~/Library/Application Support/EmojiWifi/history.json`)
  with reuse, copy, and delete actions.

## 🔄 How it works

<img src="docs/how-it-works.svg" alt="Four steps: pick a style, tune the password, get the QR code, scan or join" width="880"/>

## 🔐 The QR payload

EmojiWifi speaks the standard WiFi QR format, so codes it produces work with
any modern phone camera — and codes produced by your router work with
EmojiWifi's scanner.

<img src="docs/qr-format.svg" alt="Anatomy of the WIFI: QR payload — prefix, encryption type, SSID, password, hidden flag" width="880"/>

## ⬇️ Download & Install

**[Download the latest EmojiWifi release](https://github.com/dparksports/emoji-wifi-mac/releases/latest/download/EmojiWifi.zip)**

1. Download and extract `EmojiWifi.zip`.
2. Drag `EmojiWifi.app` into your `/Applications` folder.
3. Open it and start generating — the app is signed, so no Gatekeeper warnings.

> The live camera scanner needs camera permission; macOS will ask on first use.

## 🛠️ Build from Source

Built with SwiftUI and Swift Package Manager — no Xcode project required.

**Requirements:** macOS 13+ and Xcode Command Line Tools
(`xcode-select --install`) with a Swift 6 toolchain.

```bash
git clone https://github.com/dparksports/emoji-wifi-mac.git
cd emoji-wifi-mac
./build-app.sh
open EmojiWifi.app
```

The script compiles in release mode, assembles `EmojiWifi.app` (binary,
resource bundle, icon, `Info.plist`), and ad-hoc signs it.

> **Note for Command Line Tools 27 users:** the macOS 27 SDK implements
> SwiftUI's `@State` as a macro, but the CLT — unlike full Xcode — does not
> ship the `SwiftUIMacros` plugin it needs. `build-app.sh` detects this and
> automatically builds against the last SDK without the macro
> (`MacOSX26.5.sdk`), so builds work out of the box.

## 🗂️ Project Layout

```
emoji-wifi-mac/
├── Sources/EmojiWifi/
│   ├── ContentView.swift      # App entry point, sidebar tabs, generate view
│   ├── Views.swift            # Camera scanner, image import, UI components
│   ├── EmojiGenerator.swift   # Emoji dataset loading & WiFi name generation
│   ├── Models.swift           # Password gen, QR gen, WiFi joiner, history
│   ├── single.csv             # 533 emoji → description dataset
│   └── combos.csv             # 70 curated emoji combinations
├── build-app.sh               # Build + bundle + sign script
├── EmojiWifi.icns             # App icon
└── docs/                      # Infographics used in this README
```

## 📜 License

[Apache License 2.0](LICENSE) — feel free to use and modify it!

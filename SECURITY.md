# Security policy

EmojiWifi is fully offline: no account, no telemetry, no network calls from
the app itself. WiFi names, passwords, and history stay in
`~/Library/Application Support/EmojiWifi/` on your Mac.

The only external process it runs is `/usr/sbin/networksetup` (Auto Join),
with the SSID and password you chose, to connect your own Mac to your own
network.

## Reporting a vulnerability

Please report privately via
[GitHub security advisories](https://github.com/dparksports/emoji-wifi-mac/security/advisories/new)
— not in public issues. Include reproduction steps and affected versions.
You'll get an acknowledgement within a few days.

## Scope

- The app in this repository and its release builds
- The generated QR payloads (malformed QR text should never crash the app)
- Parsing of imported/scanned QR codes

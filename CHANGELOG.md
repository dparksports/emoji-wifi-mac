# Changelog

EmojiWifi for Mac switched to date-based versions (matching the Windows
app) with this release. Earlier versions used semver: 2.0.0 → 2.1.1.

## 2026.10.19

### Fixed

- **WiFi QR payloads now escape `\ ; , : "` in SSIDs and passwords** (port of
  the Windows v1.4.3 fix). Strong passwords containing those characters no
  longer produce broken QR codes, and scanned codes round-trip exactly.
- Scanned/imported QR codes are passed through verbatim instead of being
  re-serialized, which previously corrupted SSIDs/passwords with special
  characters.
- Passwords are generated with a cryptographically secure RNG, guaranteed to
  include at least one character from every selected class, with length
  clamped to 8–63.

### Added

- **Emoji pool grew from 533 to 1,364** — the Unicode 14.0 catalog shared
  with the Windows app (no flags or skin-tone variants, which render as
  broken boxes on some devices).
- **Emoji Picker tab**: browse all 1,364 emojis by category, search by name
  ("pizza" → 🍕), see emojis you've already used dimmed, hide them entirely,
  and tap out a custom name with a live 32-byte SSID limit.
- **"Skip emojis I've already used"** when generating random names (on by
  default).
- **Auto-generated themed combinations** per category, deterministic across
  launches and machines (same list as the Windows app's generator approach).
- History capped at 50 entries (parity with Windows).
- Test suite: QR payload escaping/round-trips, password guarantees, catalog
  integrity, used-emoji tracking, history persistence.
- CI (tests + app-bundle build check on every push/PR) and a release
  workflow that attaches **DMG + zip + SHA-256 checksums** to tagged
  releases.
- Issue templates, SUPPORT.md, SECURITY.md, this changelog.

### Changed

- Versioning switched from semver (2.1.1) to date-based (2026.10.19) to
  match the Windows app.
- Honest install notes: the app is ad-hoc signed, so macOS shows an
  "Apple cannot check it" notice on first launch — the README now documents
  exactly how to open it instead of claiming no warning. Notarization is on
  the roadmap.

### Removed

- Stray build artifacts and legacy prototype files committed to the repo
  (old single-file app, Python prototypes, stale CSV copies).

## 2.1.1 — 2026-09-23

- Maintenance release.

## 2.1.0 — 2026-03-11

- Standard app activation policy.

## 2.0.0 — 2026-02-23

- SwiftUI rewrite: generate, scan (camera + import), auto join, history.

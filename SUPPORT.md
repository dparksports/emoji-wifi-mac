# Getting help with EmojiWifi for Mac

**Quick answers first — most issues are one of these:**

## macOS blocked the app on first launch

EmojiWifi ships **ad-hoc signed**, which means it carries no paid Apple
notarization ticket. When you download it, macOS shows:

> "EmojiWifi" can't be opened because Apple cannot check it for malicious software.

The code is fully open — anyone can read every line in this repository. To open
the app:

1. Open **System Settings → Privacy & Security**.
2. Scroll down — there's a notice about EmojiWifi being blocked. Click
   **Open Anyway**. (You may need to click the 🔒 lock first.)
3. Confirm. macOS remembers your choice; subsequent launches are normal.

On macOS 13/14, right-click the app in `/Applications` → **Open** → **Open**
does the same thing.

Command-line alternative:
`xattr -d com.apple.quarantine /Applications/EmojiWifi.app`

Real notarization (which removes this notice entirely) is on the roadmap —
see the README.

## The camera scanner doesn't start

The live scanner needs camera permission. macOS asks on first use — if you
denied it, re-enable in **System Settings → Privacy & Security → Camera**.
The "Import Image" mode works without any permission.

## "Join Network" fails

Auto Join runs `/usr/sbin/networksetup -setairportnetwork en0 …`. It fails
when: the network doesn't exist yet (set the name in your router first),
your Mac uses a different interface than `en0` (check
`networksetup -listallhardwareports`), or you're on Wi-Fi that requires extra
authentication. Joining never changes your router — it only connects your Mac.

## Where is my data?

Everything stays on your Mac, offline, in
`~/Library/Application Support/EmojiWifi/history.json` (your last 50 networks).
Delete that file to wipe your history. No account, no telemetry, no network
calls.

## I lost my WiFi password

Scan or import any WiFi QR code image you saved — EmojiWifi reads the network
name and password back out of it.

---

## Reporting a bug

[Open an issue](https://github.com/dparksports/emoji-wifi-mac/issues/new/choose)
with: app version (bottom of the sidebar), macOS version, chip (Apple
Silicon/Intel), and how you installed the app. Please don't paste real
passwords — replace them with `••••`.

## Security

Found something security-relevant? Please use
[GitHub security advisories](https://github.com/dparksports/emoji-wifi-mac/security/advisories/new)
rather than a public issue. See [SECURITY.md](SECURITY.md).

## EmojiWifi family

- 🪟 [EmojiWifi for Windows](https://github.com/dparksports/emoji-wifi-windows)
- 🐧 [EmojiWifi for Ubuntu](https://github.com/dparksports/emoji-wifi-ubuntu)

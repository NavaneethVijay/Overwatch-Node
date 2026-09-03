# Overwatch Node — macOS helper

A menu bar background app (no Dock icon) that exposes this Mac's running apps
and lets the Android companion app switch focus between them. Swift Package
Manager executable — no Xcode project needed to build or run it.

## What it does

- Advertises itself over Bonjour as `_overwatchnode._tcp` so the phone finds it
  automatically on the same Wi-Fi network — no IP address to type in.
- Runs a WebSocket server (`ws://<mac>:8787/ws`, via [Swifter](https://github.com/httpswift/swifter))
  that on connect sends the current list of open/installed apps, system
  utility state (brightness, volume, Bluetooth), pushes updates as things
  change, and accepts requests to activate/open/close an app or change
  brightness/volume/take a screenshot.
- Sits in the menu bar with a status icon; no windows, no Dock icon.

See `../design/DESIGN_SYSTEM.md` and the project plan for the full wire
protocol this implements — `Sources/OverwatchNode/Protocol.swift` is the
authoritative Swift-side definition.

## Quick Start

Four steps, start to finish. Details, rationale, and troubleshooting for
each are in the sections below if something doesn't go as expected.

1. **Create a code-signing identity** — one-time, per Mac:
   - Open **Keychain Access** → menu bar **Certificate Assistant → Create a
     Certificate…**
   - Name: `Overwatch Node Dev` · Identity Type: **Self Signed Root** ·
     Certificate Type: **Code Signing** → **Create** → click through →
     **Done**.
   - Find it in Keychain Access, double-click it → expand **Trust** → set
     **Code Signing** to **Always Trust** → close (enter your password if
     asked).
2. **Build and launch**:
   ```sh
   ./run.sh
   ```
   You should see a new icon appear in the menu bar.
3. **Grant Accessibility** (needed for the screenshot trigger only): System
   Settings → Privacy & Security → Accessibility → add
   `.build/debug/OverwatchNode.app` and enable it.
4. **Pair your phone** — open the mobile app on the same Wi-Fi network; the
   Mac shows a 6-digit code (notification + menu bar → Open Overwatch
   Node…) to enter on the phone. See "Pairing" below for how this works.

If step 1 or 2 doesn't go smoothly, see "Code-signing setup" below — don't
improvise past it, the failure modes there are non-obvious.

## Run it

Once the identity from step 1 above exists, day-to-day iteration is just:

```sh
./run.sh
```

That builds, packages, kills any previous run, and relaunches it — always
use this rather than running `.build/debug/OverwatchNode` directly. Bluetooth
status requires a real `.app` bundle — a bare compiled executable
hard-crashes the moment it touches Bluetooth-adjacent APIs (see "Known
issues" below); `run.sh` handles the packaging step (`package_app.sh`) for
you.

Equivalent by hand, if you want to run each step yourself:

```sh
swift build
./package_app.sh
open .build/debug/OverwatchNode.app
```

You can confirm it's listening from another terminal:

```sh
lsof -nP -iTCP -sTCP:LISTEN | grep OverwatchNode
dns-sd -B _overwatchnode._tcp local.   # Ctrl-C to stop browsing
```

Quit it from its menu bar item ("Quit"), or `pkill -x OverwatchNode`.

## Code-signing setup

`package_app.sh` signs every build with a local, self-signed identity
named **"Overwatch Node Dev"** instead of ad-hoc (`-`) signing. This
matters because ad-hoc signatures are derived from the binary's own hash —
every `swift build` produces a different signature, so macOS silently
drops any previously granted permission (Accessibility, Bluetooth,
Automation) on the next rebuild even though Settings still shows it as
on. A stable identity keeps permissions granted once, for good.

You need this identity exactly once per machine you build on. Free, no
Apple Developer Program needed either way. The Keychain Access steps for
creating it are in "Quick Start" above (step 1) — this section is the
reference for verifying it, troubleshooting it, and the reasoning behind
each of the non-obvious parts.

Verify it's there and valid:
```sh
security find-identity -v -p codesigning | grep "Overwatch Node Dev"
```
No `(Invalid Key Usage for policy)` or similar annotation should appear
next to it — if it does, delete it (Keychain Access, or
`security delete-identity -Z <hash> ~/Library/Keychains/login.keychain-db`,
hash from `security find-identity -p codesigning`) and redo the steps
above; a mistyped Certificate Type is the usual cause.

**Alternative: `./scripts/setup-signing.sh`** does the same thing via
`openssl`/`security`, no GUI required — but treat it as experimental. In
testing, several distinct macOS/OpenSSL 3.x compatibility issues had to be
worked around (PKCS12 export format, an `add-trusted-cert` argument, a
missing X.509 extension, keychain search-list configuration) before it
produced a *listed* identity, and even then `codesign` itself still
couldn't find/use it for reasons that were never fully root-caused. The
manual steps above are what's actually been confirmed working end-to-end
(built, signed, launched, permissions persisted across rebuilds). Try the
script if you'd rather avoid the GUI, but if `./run.sh` can't find the
identity afterward, don't debug it further — just do the manual steps
instead of fighting it.

After either method, confirm the built app is actually using it:
```sh
./run.sh
codesign -dv --verbose=4 .build/debug/OverwatchNode.app 2>&1 | grep Authority
# expect: Authority=Overwatch Node Dev
```

**If `run.sh` says the identity isn't found even though `security
find-identity -v -p codesigning` shows it as valid**: your login keychain
may not actually be in your keychain *search list* (distinct from being
your *default* keychain — you can have one without the other, and
`codesign` only ever looks in the search list). Fix:
```sh
security list-keychains -d user -s ~/Library/Keychains/login.keychain-db $(security list-keychains -d user | tr -d '"')
```

## Structure

```
Sources/OverwatchNode/
  main.swift              — entry point, starts NSApplication
  AppDelegate.swift        — wires everything together, owns the status item
  AppMonitor.swift         — NSWorkspace: list/enumerate apps, watch focus changes, activate/open/close an app
  SystemUtility.swift      — brightness (private API), volume (AppleScript), screenshot trigger (CGEvent)
  BluetoothStatus.swift    — connected-device list (shells out to system_profiler)
  WebSocketServer.swift    — the /ws route, broadcast + incoming-message handling
  BonjourAdvertiser.swift  — publishes _overwatchnode._tcp
  Protocol.swift           — the JSON message types
Info.plist                 — required for Bluetooth's TCC usage-description check
package_app.sh              — wraps the built executable in a minimal .app bundle
```

## Known issues

- **Brightness control doesn't work on this machine's macOS version.** Every
  private API route tried is currently a dead end here: the long-documented
  `DisplayServicesGetBrightness`/`SetBrightness` technique (what tools like
  `brightness` (nriley) use) loads but the calls themselves fail silently;
  `CoreDisplay_Display_GetUserBrightness`/`SetUserBrightness` — confirmed to
  correctly read and change real brightness when run via `swift
  script.swift` (the interpreter) — fails to even `dlopen` ("not in dyld
  cache") once compiled as a normal executable, unsigned or not. Root cause
  not identified; `DisplayBrightness` in `SystemUtility.swift` is wired up
  and ready but currently a safe no-op (reports 50%, `setLevel` does
  nothing) rather than crashing. If you want to pick this back up: the
  interpreter-vs-compiled-binary discrepancy is the thread to pull.
- Pairing/auth exists (PIN-based, see below) but it's LAN-trust, not
  hardened security — see the root README's "Security model" section for
  the full picture and its tradeoffs.

## Pairing

The first time a new phone connects, it's shown a 6-digit code (as a
system notification and live on the Status screen's "Pairing Request"
card) that must be entered on the phone to be trusted. Codes expire after
5 minutes; a session is dropped after 5 wrong attempts. Trusted devices
are stored in `~/Library/Application Support/OverwatchNode/TrustedDevices.json`
and can be revoked from the Status screen's "Paired Devices" list. Every
message type except the initial handshake/pairing submission is refused
until a session is paired — there's no way to issue commands without
going through this once per device.

## Packaging

`package_app.sh` wraps the built executable into `.build/<config>/OverwatchNode.app`
(bundle id `com.navaneeth.overwatchnode`, signed with your local "Overwatch
Node Dev" identity — see "Code-signing setup" above, not ad-hoc — `LSUIElement`
so no Dock icon) and is required — not just nice-to-have — because Bluetooth's
TCC check refuses to work for a bare executable even with an embedded
`Info.plist` section. Re-run it after every `swift build`. Adding it to
Login Items or a proper release build is still a later step.

# Running Overwatch Node without a dev build

How to build and install standalone (release) versions of both apps —
no Metro server, no `swift build` + relaunch each time. For day-to-day
iteration, keep using `macos-app/run.sh` and `mobile-app/npm start` instead;
this is for "I just want to use the thing."

## Mac app

`macos-app/run.sh` builds in **debug** config by default. Pass `release` to
build optimized instead:

```sh
cd macos-app
./run.sh release
```

This builds, packages, code-signs (with the local "Overwatch Node Dev"
identity — see `macos-app/README.md`'s "Code-signing setup" section for
how to create it, one-time per machine), and launches
`.build/release/OverwatchNode.app`.

To stop re-running this from source and have it live as a normal app:

```sh
cp -R .build/release/OverwatchNode.app /Applications/
```

Then launch it from Spotlight/Launchpad like any other app.

**Not built yet**: Launch at Login. Right now you have to open it manually
after each restart (there's a real API for this, `SMAppService`, if it's
ever wanted).

## Android app

From `mobile-app/`:

```sh
npm run build:apk
```

Builds a release APK and copies it to `mobile-app/OverwatchNode.apk` (see
`package.json`'s `build:apk` script). Sideload that onto a device with
"install from unknown sources" allowed — it's self-signed with the debug
keystore (see `android/app/build.gradle`), which is normal for a personal,
non-Play-Store build.

Re-run this after **any** change, JS or native — a release build has no
Metro to pull live updates from, it's a frozen snapshot. After a *native*
dependency change specifically, run `npx expo prebuild --clean` first (or
`npm run android` once, which does a full native rebuild) before
`build:apk`, so the new native code is actually linked in.

**Cleartext networking**: the app talks to the Mac over plain `ws://`
(no TLS — it's LAN-only, connecting to whatever IP Bonjour discovers, not
a fixed HTTPS domain). Android blocks that by default in release builds
(release lacks the automatic debug-only exemption dev-client builds get).
Already handled via the `expo-build-properties` plugin in `app.json`
(`android.usesCleartextTraffic: true`) — if this ever needs re-checking
after a prebuild, confirm with:

```sh
grep usesCleartextTraffic android/app/src/main/AndroidManifest.xml
```

## iOS / iPad

One-time setup (per Mac used to build, and per device):

1. **Xcode** installed, with the iOS platform matching your device's OS
   version downloaded (Xcode → Settings → Components/Platforms — a build
   can succeed while still failing to *install* on-device with
   `"iOS X is not installed"` if this is missing).
2. **Developer Mode** enabled on the iPad: Settings → Privacy & Security →
   Developer Mode → toggle on → restart when prompted.
3. **Code signing**: open `mobile-app/ios/OverwatchNode.xcworkspace` in Xcode
   once, select the `OverwatchNode` target → Signing & Capabilities → pick your
   Apple ID under "Team" (a free personal-team certificate is fine for this,
   no paid Apple Developer Program needed).
4. **First install only** — after installing, the OS won't launch it until
   you trust the certificate: iPad Settings → General → VPN & Device
   Management → find your Apple ID under "Developer App" → Trust.

Build + install:

```sh
cd mobile-app
npx expo run:ios --configuration Release --device
```

Picks your connected iPad from a device list, builds a release
configuration (JS bundle embedded, no Metro needed afterward), and installs
directly. Not signed for App Store submission — this is specifically for
using it on your own device, which is exactly the point here.

**Free Apple ID limitation**: an app installed this way (not via
TestFlight/App Store) expires after **7 days** and needs reinstalling —
just rerun the command above. A paid Apple Developer Program membership
($99/year) removes that limit; not needed unless this becomes a permanent
daily-driver setup.

**Bonjour discovery on iOS**: unlike Android, iOS requires every Bonjour
service type an app browses for to be explicitly declared, or discovery
silently finds nothing regardless of permission state. Already configured
in `app.json` (`ios.infoPlist.NSBonjourServices` includes `_overwatchnode._tcp`)
— if discovery ever mysteriously stops working after a prebuild, check that
key is still there.

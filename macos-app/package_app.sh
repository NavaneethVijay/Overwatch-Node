#!/bin/sh
# Wraps the built executable in a minimal .app bundle. Needed because some
# TCC-protected APIs (Bluetooth, at least) refuse to work — hard-crashing
# with SIGABRT — for a bare command-line executable, even one with an
# embedded Info.plist section; they specifically require a real .app bundle
# with a resolvable CFBundleIdentifier. Run this after `swift build`.
set -e

cd "$(dirname "$0")"

CONFIG="${1:-debug}"
BIN_PATH=".build/$CONFIG/OverwatchNode"
APP_DIR=".build/$CONFIG/OverwatchNode.app"

# Overridable so a fork/rename doesn't have to touch this script — see
# scripts/setup-signing.sh, which creates an identity with this exact name.
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Overwatch Node Dev}"

if [ ! -f "$BIN_PATH" ]; then
    echo "error: $BIN_PATH not found — run 'swift build' first" >&2
    exit 1
fi

if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "$SIGNING_IDENTITY"; then
    echo "error: code-signing identity \"$SIGNING_IDENTITY\" not found in your keychain." >&2
    echo "Run ./scripts/setup-signing.sh once to create it (or see README.md's" >&2
    echo "\"Code-signing setup\" section for the manual steps), then try again." >&2
    exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/OverwatchNode"
cp Sources/OverwatchNode/Info.plist "$APP_DIR/Contents/Info.plist"

# Now Playing's MediaRemote adapter (see NowPlaying.swift) — a small dylib
# loaded by /usr/bin/perl at runtime, not part of the SwiftPM build graph.
# Ported from https://github.com/codexjdub/NowPlaying: Apple-signed perl
# has the private-framework access a third-party process doesn't, so
# calling MRMediaRemoteGetNowPlayingInfo from a dylib loaded into perl
# (via Perl's own DynaLoader — Resources/adapter.pl) returns real data.
clang -dynamiclib -fobjc-arc -fvisibility=hidden -O2 \
    -framework Foundation -framework CoreFoundation \
    -o "$APP_DIR/Contents/Resources/MediaRemoteAdapter.dylib" \
    Resources/MediaRemoteAdapter.m
cp Resources/adapter.pl "$APP_DIR/Contents/Resources/adapter.pl"
chmod +x "$APP_DIR/Contents/Resources/adapter.pl"

# Info.plist only carries the usage-description strings; fill in the rest
# of what makes this a real bundle (bundle id, executable name, no Dock
# icon) without hand-maintaining two plists.
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.navaneeth.overwatchnode" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleName string OverwatchNode" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string OverwatchNode" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true

# Signed with a local self-signed "Overwatch Node Dev" identity (created by
# scripts/setup-signing.sh, or manually via Keychain Access > Certificate
# Assistant > Create a Certificate > Code Signing, trusted "Always Trust")
# rather than ad-hoc (`-`). Ad-hoc signatures are derived from the binary's
# own hash, so every `swift build` produces a different signature — TCC
# then treats each rebuild as a brand-new app and silently drops any
# previously granted permission (Accessibility, Bluetooth, Automation),
# even though the Settings toggle still shows "on". A stable signing
# identity keeps the same identity across rebuilds, so a granted
# permission actually persists.
codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_DIR"

echo "Packaged: $APP_DIR"

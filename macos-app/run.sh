#!/bin/sh
# One-command build + package + (re)launch. Always use this instead of
# running .build/debug/OverwatchNode directly — see package_app.sh for why.
set -e

cd "$(dirname "$0")"

CONFIG="${1:-debug}"

if [ "$CONFIG" = "release" ]; then
    swift build -c release
else
    swift build
fi
./package_app.sh "$CONFIG"

# Kill any previous run so the new build actually takes effect — `open` on
# an already-running app just brings the old one to the front.
pkill -x OverwatchNode 2>/dev/null || true
sleep 0.5

open ".build/$CONFIG/OverwatchNode.app"
echo "Overwatch Node running — check the menu bar for its icon."

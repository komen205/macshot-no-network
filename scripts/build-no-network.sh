#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build/dist
build_log="$PWD/build/no-network-build.log"
if ! xcodebuild -scheme macshot -configuration Release \
    -derivedDataPath build/no-network \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
    build > "$build_log" 2>&1; then
    tail -n 40 "$build_log"
    exit 1
fi

app="build/no-network/Build/Products/Release/macshot Offline No Network.app"
python3 scripts/check-no-network.py --app "$app"
ditto -c -k --sequesterRsrc --keepParent "$app" "build/dist/MacShot-No-Network.zip"
printf 'App: %s/%s\nArchive: %s/build/dist/MacShot-No-Network.zip\n' "$PWD" "$app" "$PWD"

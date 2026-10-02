# Privacy: macshot Offline No Network

Updated October 2, 2026. This document describes this fork.

The signed app uses App Sandbox without network-client or network-server grants.
Uploads and cloud authentication are compiled out. Sparkle is removed, translation
is disabled, and external URLs cannot launch a browser from the app.

Screenshots, recordings, editable history and preferences are stored locally.
The save destination and screenshot-history retention remain user-controlled.
Clipboard contents are available to other applications through macOS. Files saved
to a synced folder can be uploaded by the service managing that folder.

Screen Recording permission is required to capture the screen. Optional recording
features can request microphone, camera or speech recognition permission. Caption
recognition requires on-device support and refuses a cloud fallback.

This fork adds no telemetry or analytics. App network restrictions do not control
traffic from unrelated macOS services or other applications. Building the source
may fetch dependencies; downloading a release also uses your browser's network.

For implementation and test details, see [the README](README.md) and
[the network patch guide](docs/no-network.md). Upstream macshot's policy is
[available separately](https://github.com/sw33tLie/macshot/blob/4c1361e4a237a005495f2eb5a6859503ee7a9526/PRIVACY.md).

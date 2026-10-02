# Why does my screenshot app make network requests?

I wanted to take a screenshot, add some text and arrows, and copy it.
I wanted the screenshot app to have **no network access**.

This is a fork of [macshot](https://github.com/sw33tLie/macshot) with network
access denied by the macOS sandbox, plus its network features removed or disabled.

## What was making requests?

macshot has useful features that need networking:

| Feature | Network use in upstream macshot | This fork |
| --- | --- | --- |
| Automatic updates | Sparkle checks a GitHub-hosted update feed | Updater and feed removed |
| Google Translate | Sends selected text to Google's translation endpoint when used | Disabled |
| Cloud uploads | Sends captures to Google Drive, imgbb or an S3-compatible service when used | Compiled out |
| Apple Translation | Can require language-pack downloads | Disabled |
| Search and QR links | Can open a browser with screenshot text or a decoded URL | External URL launches blocked |

These are identifiable product features. This project makes no claim that
upstream macshot is spying on users. Its [upstream privacy policy](https://github.com/sw33tLie/macshot/blob/4c1361e4a237a005495f2eb5a6859503ee7a9526/PRIVACY.md)
says it does not collect telemetry or analytics.

The upstream “Offline” variant removes uploads, but still includes update checks
and translation. This fork goes further: **the signed app has App Sandbox enabled
and neither a network-client nor a network-server entitlement**.

## What still works?

Screenshots, text, arrows, shapes, highlighting, blur, clipboard output, local
saves, screenshot history and the image editor remain available. OCR runs locally.
The core capture and annotation implementation comes from macshot.

The app is named **macshot Offline No Network**, with separate application
permissions and preferences. Capture with **Command-Shift-X**, annotate, then
**Command-C** to copy.

## Install

Download **MacShot-No-Network.zip** from [Releases](https://github.com/komen205/macshot-no-network/releases).
Extract it, drag the app to Applications, and grant Screen Recording on first launch.

The published build is locally signed, **not Apple-notarized**. If macOS blocks
it, allow it in System Settings → Privacy & Security after trying to open it.
Updates are manual; this app cannot check for or download updates.

## Build it yourself

Requires Xcode. The build tools may download Swift-WebP; this is separate from
network permissions in the resulting app.

```sh
git clone https://github.com/komen205/macshot-no-network.git
cd macshot-no-network
bash scripts/build-no-network.sh
```

The script builds a universal Release app, verifies its signature and network
permissions, tests the sandbox block, and packages `build/dist/MacShot-No-Network.zip`.

## How is the block verified?

The local test run passed **787 tests**. A separate probe verifies TCP, UDP and
URLSession HTTP against a loopback server. They succeed without a sandbox; with
the app's entitlement file, sockets fail with `EPERM` and URLSession is denied.
The build check also rejects network entitlements, updater configuration and
embedded Sparkle files. CI runs the tests and the same build check.

```sh
bash scripts/run-tests.sh
python3 scripts/check-no-network.py --app \
  'build/no-network/Build/Products/Release/macshot Offline No Network.app'
```

These checks verify the app's network permissions. They do not control unrelated
macOS services, browsers or applications. Screen capture and annotation require
a manual check after granting Screen Recording permission.

See [patch and build details](docs/no-network.md) and [privacy](PRIVACY.md).

## Credit and license

Built on [sw33tLie/macshot](https://github.com/sw33tLie/macshot), based on commit
`4c1361e4a237a005495f2eb5a6859503ee7a9526`. The original authors built the app;
this fork changes its network capabilities. [GPLv3](LICENSE).

# macshot with network access denied

This local fork is based on upstream commit
`4c1361e4a237a005495f2eb5a6859503ee7a9526`. The patch is maintained in this repository.

The app is named **macshot Offline No Network** and uses bundle identifier
`com.local.macshot.nonetwork`, so it has separate permissions and preferences.

## Changes

- The signed app retains App Sandbox but has neither network-client nor
  network-server entitlements. macOS denies its outgoing network connections.
- The existing `OFFLINE` compilation condition is enabled in Debug and Release,
  excluding uploads, authentication, cloud settings and upload UI. The app entry
  point rejects builds that omit this condition.
- Sparkle is removed from the project and app. Update checks, installer services,
  feeds and update controls are removed.
- Translation is disabled entirely, including Google requests and Apple
  language-pack downloads. Text recognition (OCR) still runs locally.
- External URL launches are refused so QR codes, search and website buttons
  cannot hand screenshot text to a browser. Local files and macOS permission
  settings can still open.

Screen capture, arrows, editable text, blur, clipboard output, local saves,
history and the image editor remain available. Translation actions report that
translation is disabled. Updates require rebuilding this fork manually.

## Build and install

Requires Xcode. Building may download the Swift-WebP dependency; that is build
tool traffic, separate from the resulting app's runtime permissions.

```sh
bash scripts/build-no-network.sh
```

The script makes a universal Release app, signs it locally, checks its signature
and entitlements, tests network denial, and creates:

`build/dist/MacShot-No-Network.zip`

Extract the archive, drag **macshot Offline No Network.app** to Applications,
then open it. Grant Screen Recording when macOS requests it. Capture with
**Command-Shift-X**, choose text or arrows, then **Command-C** to copy.

The build is locally signed, not Apple-notarized. It does not inherit the upstream
developer's signature. macOS may require allowing it in Privacy & Security if
the archive has acquired a quarantine attribute.

## Verification

```sh
bash scripts/run-tests.sh
python3 scripts/check-no-network.py --app \
  'build/no-network/Build/Products/Release/macshot Offline No Network.app'
```

The network check first confirms TCP, UDP and URLSession HTTP work against its
own loopback fixture without a sandbox. It then signs the same probe with the
app's exact entitlement file and verifies both socket connections fail with
`EPERM` and URLSession fails. It also verifies the built app is sandboxed,
has no network grants, has no update configuration and embeds no Sparkle files.

This verifies the app's network permissions, not traffic from unrelated macOS
services or other applications. Capture and annotation still need a manual
check after Screen Recording permission is granted.

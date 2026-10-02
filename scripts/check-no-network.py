#!/usr/bin/env python3
"""Verify actual TCP, UDP and URLSession denial using the app's signed entitlements."""
import json
import plistlib
import socket
import subprocess
import tempfile
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTITLEMENTS = ROOT / "macshot/macshot.entitlements"


def run(*arguments):
    return subprocess.run(arguments, check=True, capture_output=True, text=True).stdout


def serve(listener):
    while True:
        connection, _ = listener.accept()
        with connection:
            if connection.recv(1024):
                connection.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK")


def check_bundle(app):
    run("codesign", "--verify", "--deep", "--strict", str(app))
    result = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(app)],
                            check=True, capture_output=True)
    entitlements = plistlib.loads(result.stdout)
    assert entitlements.get("com.apple.security.app-sandbox") is True
    assert not any(value for key, value in entitlements.items() if "network" in key), entitlements
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    assert not any(key.startswith("SU") for key in info), "Updater configuration remains"
    assert not any("sparkle" in str(path).lower() for path in app.rglob("*")), "Sparkle is embedded"
    print("Built app: valid signature, sandbox enabled, no network grants or updater")


def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, help="Also verify a built app bundle")
    args = parser.parse_args()
    entitlements = plistlib.loads(ENTITLEMENTS.read_bytes())
    assert entitlements.get("com.apple.security.app-sandbox") is True
    assert not any(value for key, value in entitlements.items() if "network" in key)
    if args.app:
        check_bundle(args.app)

    with socket.socket() as tcp, socket.socket(type=socket.SOCK_DGRAM) as udp:
        tcp.bind(("127.0.0.1", 0))
        port = tcp.getsockname()[1]
        tcp.listen()
        udp.bind(("127.0.0.1", port))
        threading.Thread(target=serve, args=(tcp,), daemon=True).start()
        with tempfile.TemporaryDirectory(prefix="macshot-network-check-") as directory:
            directory = Path(directory)
            executable = directory / "probe"
            run("xcrun", "swiftc", str(ROOT / "scripts/network-probe.swift"), "-o", str(executable))
            baseline = json.loads(run(str(executable), str(port)))
            assert baseline["tcp"]["result"] == 0, baseline
            assert baseline["udp"]["result"] == 0, baseline
            assert baseline["http"]["success"], baseline

            app = directory / "NetworkProbe.app"
            binary = app / "Contents/MacOS/probe"
            binary.parent.mkdir(parents=True)
            binary.write_bytes(executable.read_bytes())
            binary.chmod(0o755)
            (app / "Contents/Info.plist").write_bytes(plistlib.dumps({
                "CFBundleIdentifier": "com.local.macshot.networkprobe",
                "CFBundleExecutable": "probe",
                "CFBundlePackageType": "APPL",
                "NSAppTransportSecurity": {"NSAllowsLocalNetworking": True},
            }))
            run("codesign", "--force", "--sign", "-", "--entitlements", str(ENTITLEMENTS), str(app))
            blocked = json.loads(run(str(binary), str(port)))
            for protocol in ("tcp", "udp"):
                assert blocked[protocol] == {"result": -1, "errno": 1}, blocked
            assert not blocked["http"]["success"], blocked
            print("Unrestricted control: TCP, UDP and URLSession succeed against localhost")
            print("App entitlements: TCP and UDP denied with EPERM; URLSession denied")
            print(json.dumps(blocked, indent=2))


if __name__ == "__main__":
    main()

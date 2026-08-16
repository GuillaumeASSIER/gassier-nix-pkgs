#!/usr/bin/env python3
"""Regenerate pkgs/opencode/sources.json from the latest GitHub release of
anomalyco/opencode (the stable v1 line, whose binary is named `opencode`).

Usage: update.py <path-to-sources.json>

Fetches the latest GitHub release, then downloads each platform archive
(.tar.gz on Linux, .zip on macOS), computes its SRI sha256 hash, and
overwrites sources.json.
"""
import base64
import hashlib
import json
import sys
import urllib.request

REPO = "anomalyco/opencode"
API_URL = f"https://api.github.com/repos/{REPO}/releases/latest"
# nix system -> GitHub release asset name
PLATFORMS = {
    "x86_64-linux": "opencode-linux-x64.tar.gz",
    "aarch64-linux": "opencode-linux-arm64.tar.gz",
    "x86_64-darwin": "opencode-darwin-x64.zip",
    "aarch64-darwin": "opencode-darwin-arm64.zip",
}


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "nix-update"})
    with urllib.request.urlopen(req) as resp:  # noqa: S310 (trusted registry URL)
        return resp.read()


def sri_sha256(data):
    return "sha256-" + base64.b64encode(hashlib.sha256(data).digest()).decode()


def main():
    out_path = sys.argv[1]
    meta = json.loads(fetch(API_URL))
    tag = meta["tag_name"]  # e.g. v1.18.18
    assert tag.startswith("v")
    version = tag[1:]
    assets = {a["name"]: a for a in meta["assets"]}

    platforms = {}
    for system, asset_name in PLATFORMS.items():
        url = assets[asset_name]["browser_download_url"]
        platforms[system] = {"asset": asset_name, "hash": sri_sha256(fetch(url))}
        print(f"  {system}: {asset_name} -> {platforms[system]['hash']}", file=sys.stderr)

    result = {"version": version, "platforms": platforms}
    with open(out_path, "w") as f:
        json.dump(result, f, indent=2)
        f.write("\n")
    print(f"updated {out_path} -> {version}", file=sys.stderr)


if __name__ == "__main__":
    main()

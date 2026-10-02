#!/usr/bin/env python3
"""Regenerate pkgs/msgvault/sources.json from the latest GitHub release of
kenn-io/msgvault.

Usage: update.py <path-to-sources.json>

Fetches the latest GitHub release, then downloads each platform archive
(msgvault_<version>_<os>_<arch>.tar.gz), computes its SRI sha256 hash, and
overwrites sources.json.
"""
import base64
import hashlib
import json
import sys
import urllib.request

REPO = "kenn-io/msgvault"
API_URL = f"https://api.github.com/repos/{REPO}/releases/latest"
# nix system -> (os, arch) components of the GitHub release asset name
PLATFORMS = {
    "x86_64-linux": ("linux", "amd64"),
    "aarch64-linux": ("linux", "arm64"),
    "x86_64-darwin": ("darwin", "amd64"),
    "aarch64-darwin": ("darwin", "arm64"),
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
    tag = meta["tag_name"]  # e.g. v0.20.0
    assert tag.startswith("v")
    version = tag[1:]
    assets = {a["name"]: a for a in meta["assets"]}

    platforms = {}
    for system, (os_name, arch) in PLATFORMS.items():
        asset_name = f"msgvault_{version}_{os_name}_{arch}.tar.gz"
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

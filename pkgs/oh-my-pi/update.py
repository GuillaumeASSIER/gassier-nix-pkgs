#!/usr/bin/env python3
"""Regenerate pkgs/oh-my-pi/sources.json from the latest GitHub release of
can1357/oh-my-pi.

Usage: update.py <path-to-sources.json>

Fetches the latest GitHub release, then downloads each platform binary
(glibc builds: omp-linux-*/omp-darwin-*), computes its SRI sha256 hash, and
overwrites sources.json.
"""
import base64
import hashlib
import json
import sys
import urllib.request

REPO = "can1357/oh-my-pi"
API_URL = f"https://api.github.com/repos/{REPO}/releases/latest"
# nix system -> GitHub release asset name (raw binary, no archive wrapper)
PLATFORMS = {
    "x86_64-linux": "omp-linux-x64",
    "aarch64-linux": "omp-linux-arm64",
    "x86_64-darwin": "omp-darwin-x64",
    "aarch64-darwin": "omp-darwin-arm64",
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
    tag = meta["tag_name"]  # e.g. v17.3.5
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
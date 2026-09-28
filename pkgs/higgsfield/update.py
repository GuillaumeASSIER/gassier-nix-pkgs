#!/usr/bin/env python3
"""Regenerate pkgs/higgsfield/sources.json from the latest GitHub release of
higgsfield-ai/cli.

Usage: update.py <path-to-sources.json>

Fetches the latest GitHub release, then downloads each platform archive
(hf_<version>_<os>_<arch>.tar.gz, containing the static `hf` binary), computes
its SRI sha256 hash, and overwrites sources.json.
"""
import base64
import hashlib
import json
import sys
import urllib.request

REPO = "higgsfield-ai/cli"
API_URL = f"https://api.github.com/repos/{REPO}/releases/latest"
# nix system -> release asset name template
PLATFORMS = {
    "x86_64-linux": "hf_{version}_linux_amd64.tar.gz",
    "aarch64-linux": "hf_{version}_linux_arm64.tar.gz",
    "x86_64-darwin": "hf_{version}_darwin_amd64.tar.gz",
    "aarch64-darwin": "hf_{version}_darwin_arm64.tar.gz",
}


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "nix-update"})
    with urllib.request.urlopen(req) as resp:  # noqa: S310 (trusted release URL)
        return resp.read()


def sri_sha256(data):
    return "sha256-" + base64.b64encode(hashlib.sha256(data).digest()).decode()


def main():
    out_path = sys.argv[1]
    meta = json.loads(fetch(API_URL))
    tag = meta["tag_name"]  # e.g. v1.1.26
    assert tag.startswith("v")
    version = tag[1:]
    assets = {a["name"]: a for a in meta["assets"]}

    platforms = {}
    for system, template in PLATFORMS.items():
        asset_name = template.format(version=version)
        asset = assets[asset_name]
        platforms[system] = {
            "asset": asset_name,
            "hash": sri_sha256(fetch(asset["browser_download_url"])),
        }
        print(f"  {system}: {asset_name} -> {platforms[system]['hash']}", file=sys.stderr)

    result = {"version": version, "platforms": platforms}
    with open(out_path, "w") as f:
        json.dump(result, f, indent=2)
        f.write("\n")
    print(f"updated {out_path} -> {version}", file=sys.stderr)


if __name__ == "__main__":
    main()

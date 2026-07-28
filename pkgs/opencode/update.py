#!/usr/bin/env python3
"""Regenerate pkgs/opencode/sources.json from the npm "next" dist-tag.

Usage: update.py <path-to-sources.json>

Fetches the @opencode-ai/cli dist-tag "next", then downloads each platform
tarball, computes its SRI sha256 hash, and overwrites sources.json.
"""
import base64
import hashlib
import json
import sys
import urllib.request

REGISTRY = "https://registry.npmjs.org/@opencode-ai/cli"
# nix system -> npm platform package suffix
PLATFORMS = {
    "x86_64-linux": "linux-x64",
    "aarch64-linux": "linux-arm64",
    "x86_64-darwin": "darwin-x64",
    "aarch64-darwin": "darwin-arm64",
}


def fetch(url):
    with urllib.request.urlopen(url) as resp:  # noqa: S310 (trusted registry URL)
        return resp.read()


def sri_sha256(data):
    return "sha256-" + base64.b64encode(hashlib.sha256(data).digest()).decode()


def main():
    out_path = sys.argv[1]
    meta = json.loads(fetch(REGISTRY))
    version = meta["dist-tags"]["next"]

    platforms = {}
    for system, npm in PLATFORMS.items():
        url = f"https://registry.npmjs.org/@opencode-ai/cli-{npm}/-/cli-{npm}-{version}.tgz"
        platforms[system] = {"npm": npm, "hash": sri_sha256(fetch(url))}
        print(f"  {system}: {npm} -> {platforms[system]['hash']}", file=sys.stderr)

    result = {"version": version, "platforms": platforms}
    with open(out_path, "w") as f:
        json.dump(result, f, indent=2)
        f.write("\n")
    print(f"updated {out_path} -> {version}", file=sys.stderr)


if __name__ == "__main__":
    main()

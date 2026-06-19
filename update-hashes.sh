#!/usr/bin/env bash
# Script to update hashes for mimo-code package
# Usage: ./update-hashes.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="$SCRIPT_DIR/pkgs/mimo-code/package.nix"

echo "📦 Updating hashes for mimo-code package..."
echo ""

if ! command -v nix-build &> /dev/null; then
    echo "❌ Error: nix-build is not installed or not in PATH"
    exit 1
fi

if ! command -v nix-hash &> /dev/null; then
    echo "❌ Error: nix-hash is not installed or not in PATH"
    exit 1
fi

echo "🔄 Building package to discover hashes..."
echo ""

# Try to build and capture the hash from error message
if nix build ".#mimo-code" -L 2>&1 | tee /tmp/build.log; then
    echo "✅ Build succeeded!"
else
    echo "⏳ Build attempted. Extracting hash from error message..."
    
    # Extract hash from error message
    if grep -q "hash mismatch" /tmp/build.log; then
        echo ""
        echo "📋 Hash information from build:"
        grep -A 2 "hash mismatch" /tmp/build.log || true
        echo ""
        echo "Update the hash in $PACKAGE_FILE"
    fi
fi

echo ""
echo "Alternative: Use nix-prefetch-url"
echo ""
echo "# For the source code:"
echo "nix-prefetch-url --unpack https://github.com/XiaomiMiMo/MiMo-Code/archive/refs/tags/v0.1.1.tar.gz"
echo ""
echo "Then replace lib.fakeHash with the hash returned above."

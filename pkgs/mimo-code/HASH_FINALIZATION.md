# Finalizing MiMo-Code Package Hashes

## Current Status

The package has been locked to the latest stable release: **v0.1.1** (released June 15, 2026).

- ✅ Version: `0.1.1`
- ✅ Rev: `v0.1.1` (stable tag, not main branch)
- ⏳ Hash: Currently using `lib.fakeHash` (placeholder)

## Next Step: Generate the Real Hash

To finalize the package with the correct hash, you have two options:

### Option 1: Automatic Script (Recommended)

Run the provided helper script:

```bash
./update-hashes.sh
```

This will attempt to build the package and extract the hash from the error message, then guide you to update the `package.nix` file.

### Option 2: Manual Method with nix-prefetch-url

```bash
# 1. Get the source hash
nix-prefetch-url --unpack https://github.com/XiaomiMiMo/MiMo-Code/archive/refs/tags/v0.1.1.tar.gz

# 2. Replace lib.fakeHash in pkgs/mimo-code/package.nix with the returned hash
```

### Option 3: Build and Extract Hash

```bash
# 1. Try to build (will fail with hash mismatch)
nix build .#mimo-code 2>&1 | tee build.log

# 2. Extract the hash from the error message
grep -A 2 "hash mismatch" build.log

# 3. Update package.nix with the correct hash
```

## What to Update

Edit [pkgs/mimo-code/package.nix](package.nix) and find:

```nix
src = fetchFromGitHub {
  owner = "XiaomiMiMo";
  repo = "MiMo-Code";
  rev = "v${finalAttrs.version}";
  hash = lib.fakeHash;  # <- Replace this
};
```

Replace `lib.fakeHash` with the actual hash (format: `sha256-...`).

## GitHub Release Information

- **Release Tag**: `v0.1.1`
- **Released**: June 15, 2026
- **Release Page**: https://github.com/XiaomiMiMo/MiMo-Code/releases/tag/v0.1.1
- **Source Archive**: https://github.com/XiaomiMiMo/MiMo-Code/archive/refs/tags/v0.1.1.tar.gz

## Benefits of This Approach

✅ **Stable Release**: Uses official releases instead of following main branch  
✅ **Reproducible**: Hash locks the exact source code  
✅ **Easy Updates**: Simply bump version and Renovate Bot can automate updates  
✅ **Security**: Avoid building from development branches with unstable code

## Troubleshooting

### "nix-prefetch-url: command not found"

Install it:
```bash
nix-env -iA nixpkgs.nix
```

### Hash doesn't match

Make sure you're using the exact tag: `v0.1.1` (note the `v` prefix)

### Build still fails after hash update

Check the build logs:
```bash
nix build .#mimo-code -L 2>&1 | tail -50
```

The issue might be:
- Network/proxy problems during dependency installation
- Missing native build tools
- Platform-specific issues (check `platforms` in package.nix)

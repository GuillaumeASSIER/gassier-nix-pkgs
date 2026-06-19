# Finalizing Godap Package Hashes

## Current Status

The package has been configured for the latest stable release: **v2.11.0** (released March 4, 2026).

- ✅ Version: `2.11.0`
- ✅ Rev: `v2.11.0` (stable tag)
- ✅ Source Hash: Pre-computed
- ⏳ Vendor Hash: Currently using `lib.fakeHash` (placeholder)

## Next Step: Generate the Real Vendor Hash

To finalize the package with the correct vendor hash, follow these steps:

### Option 1: Automatic with nix (Recommended)

```bash
# 1. Try to build the package (it will fail with a hash mismatch)
nix build .#godap 2>&1 | tee build.log

# 2. Find the vendor hash in the error message
grep -i "got:" build.log | grep sha256

# 3. Copy the hash (e.g., sha256-xxxx...) and update package.nix
```

### Option 2: Using nix-prefetch-git

```bash
nix-prefetch-git https://github.com/Macmod/godap --rev v2.11.0
```

### Option 3: Manual Verification

If you have `go` installed locally:

```bash
cd /tmp
git clone --depth 1 --branch v2.11.0 https://github.com/Macmod/godap.git
cd godap
go mod vendor
# The vendor directory hash will be needed for vendorHash
```

## What to Update

Edit [pkgs/godap/package.nix](package.nix) and find:

```nix
vendorHash = lib.fakeHash;
```

Replace it with the actual hash (e.g., `vendorHash = "sha256-xxxxxxxx...";`).

## Testing

After updating the hash, verify the package builds correctly:

```bash
nix build .#godap
```

## References

- [buildGoModule documentation](https://nixos.org/manual/nixpkgs/stable/#sec-language-go)
- [godap GitHub repository](https://github.com/Macmod/godap)

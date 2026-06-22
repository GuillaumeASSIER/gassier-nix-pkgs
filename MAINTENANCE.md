# Package Maintenance Guide

## Hash Updates

When updating a package version, you must update the SHA256 hashes.

### Automated Method (Recommended)

```bash
nix-update mimo-code
```

### Manual Method

1. Change the `rev` (or `tag`) in `fetchFromGitHub`
2. Use `lib.fakeHash` temporarily:

```nix
hash = lib.fakeHash;
```

3. Try a build to get the real hash:

```bash
nix build .#mimo-code 2>&1 | grep "got:"
```

4. Replace `lib.fakeHash` with the correct hash in `package.nix`

## Updating `node_modules`

When updating Node/Bun dependencies:

1. First change the `node_modules` hash to `lib.fakeHash`
2. Run a build to get the new hash
3. Update the hash in the `package.nix` file

## Pre-Merge Verification

Before merging a pull request:

```bash
# Verify that the flake can be built
nix build

# Check syntax
nix flake check

# Display structure
nix flake show
```

## Troubleshooting

### Build Fails with "hash mismatch"

This means the content has changed. Use the hash suggested in the error message.

### npm/Bun Cache Issues

Dependencies may not be fully reproducible. Use `lib.fakeHash` to discover the real hash, then add it.

### Platform-Specific Configuration

The package is configured to work on:
- `aarch64-linux`
- `x86_64-linux`
- `aarch64-darwin`
- `x86_64-darwin`

If you encounter platform-specific issues, check the conditions in `package.nix`.

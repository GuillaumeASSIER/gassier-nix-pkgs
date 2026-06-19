# Setup Summary

## What Has Been Configured

### 1. Nix Flake Structure
- **flake.nix**: Flake definition exposing two packages and a devShell.
- `godap` is the default package; `mimo-code` is the second one.
- `devShells.default` provides `bun`, `nodejs`, `nix-update`, `nix-prefetch-git`
  and `nix-prefetch` for maintenance.

### 2. Packages

#### godap (default)
- **pkgs/godap/package.nix**: `buildGoModule` derivation for the LDAP TUI.
- Source: Macmod/godap v2.11.0
- Both `src` and `vendorHash` are pinned and verified to build.

#### mimo-code
- **pkgs/mimo-code/package.nix**: `stdenvNoCC.mkDerivation` adapted from the
  upstream `nix/opencode.nix` packaging.
- Source: XiaomiMiMo/MiMo-Code v0.1.1
- Build: filtered `bun install` -> `bun --bun ./script/build.ts --single
  --skip-install` -> compiled native binary exposed as `mimo-code`.
- `node_modules` is a fixed-output derivation pinned via `outputHash`.
- `postPatch` works around two v0.1.1 upstream bugs (missing
  `packages/opencode/src/plugin/mimo-free.ts` and `prettier` import in the
  `generate` command).
- Helper scripts `canonicalize-node-modules.ts` and
  `normalize-bun-binaries.ts` are vendored under
  `pkgs/mimo-code/scripts/` so the derivation is self-contained.

### 3. Automation & CI/CD
- **renovate.json**: Renovate Bot configuration (weekly updates, auto-merge
  for types/devDeps, semantic commits).
- **.github/workflows/**: CI flake check, Renovate Bot execution, daily update
  checks.

### 4. Documentation
- **README.md**: Main installation and usage guide.
- **QUICKSTART.md**: Quick start guide.
- **MAINTENANCE.md**: Package maintenance and hash update guide.
- **CONTRIBUTING.md**: Contribution guide.

### 5. Development Tools
- **.envrc**: `use flake` for automatic direnv configuration.
- **.gitignore**: Nix + Node/Bun patterns.

## Verification

```bash
nix flake show       # list outputs
nix flake check      # check all systems (use --all-systems for cross-arch)
nix build            # build the default package (godap)
nix build .#mimo-code
nix run .#mimo-code -- --version
```

## Useful Commands

```bash
# Update a package's version (from the devShell)
nix-update mimo-code
nix-update godap

# Enter the devshell
nix develop
```

# MiMo-Code Package

Nix package for [MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code) - a highly customizable code editor based on modern web technologies.

## Description

MiMo-Code is a custom adaptation of a code editor. This Nix package adapts it from the original `opencode` package (see [NixOS nixpkgs](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/op/opencode/package.nix)).

### Key Adaptations

1. **Repository**: Changed to `XiaomiMiMo/MiMo-Code`
2. **Simplified Dependencies**: Removed `models-dev` and other opencode-specific dependencies
3. **Build Configuration**: Adapted for the MiMo-Code repository structure
4. **Environment**: Environment variables renamed to `MIMO_CODE_*`

## Installation

### Via Nix Flake

```bash
nix profile install github:GuillaumeASSIER/gassier-nix-pkgs#mimo-code
```

### As a Dependency of Another Flake

```nix
{
  inputs.gassier-nix-pkgs.url = "github:GuillaumeASSIER/gassier-nix-pkgs";
  
  outputs = { gassier-nix-pkgs, ... }:
    {
      packages.x86_64-linux.default = gassier-nix-pkgs.packages.x86_64-linux.mimo-code;
    };
}
```

## Usage

Once installed, launch MiMo-Code with:

```bash
mimo-code
```

## Runtime Dependencies

- `ripgrep` (rg) - Fast file search (wrapped into PATH)

## Build Architecture

The package builds MiMo-Code from source, closely following the upstream `nix/`
packaging. Two derivations are composed:

1. **`node_modules` derivation** (fixed-output):
   - Filters workspaces with `bun install --filter ./packages/opencode ...`
   - Runs the upstream `canonicalize-node-modules` and `normalize-bun-binaries`
     scripts so the store output is reproducible.
   - Pinned via `outputHash` (recursive sha256).

2. **Main derivation**:
   - `configurePhase`: copies the prebuilt `node_modules` over the source and
     patches shebangs.
   - `postPatch`: stubs the missing `packages/opencode/src/plugin/mimo-free.ts`
     and removes the `prettier` import from the `generate` command (both are
     v0.1.1 upstream bugs, fixed in `main`).
   - `buildPhase`: runs `bun --bun ./script/build.ts --single --skip-install`
     inside `packages/opencode` to compile a single native binary via
     `Bun.build({ compile })`, plus `script/schema.ts schema.json`.
   - `installPhase`: exposes the compiled binary as `mimo-code` (the upstream
     binary is named `mimo`) and installs the JSON schema under
     `$out/share/mimo-code`.
   - Shell completions are generated for bash and zsh.

## Updating

Use the standard Nix tooling from the devShell:

```bash
nix-update mimo-code
# or, for godap:
nix-update godap
```

See [MAINTENANCE.md](../MAINTENANCE.md) for manual instructions.

## Known Limitations

- The `mimo-free` auth plugin is stubbed out in this build (the upstream
  `v0.1.1` tag references a file that is not committed to the repository). The
  `mimo-free` provider choice will raise at runtime; use `mimo` instead.
- The `generate` command emits raw JSON (prettier formatting is skipped, see
  `postPatch` in `package.nix`).

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

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

- `bun` - JavaScript runtime with Bun
- `nodejs` - JavaScript/Node.js runtime
- `ripgrep` (rg) - Fast file search

## Build Architecture

1. **`node_modules` Phase**: 
   - Installs npm dependencies via `bun install`
   - Creates reproducible Node modules output

2. **`configure` Phase**: 
   - Copies precompiled `node_modules`
   - Patches shebangs

3. **`build` Phase**: 
   - Runs `bun install` to finalize installation
   - Executes build scripts (`bun run build`)

4. **`install` Phase**: 
   - Copies build artifacts to `$out/share/mimo-code/`
   - Creates a wrapper to execute the binary
   - Exposes `mimo-code` command in PATH

## Debugging

### Show Build Steps

```bash
nix build -L
```

### Interactive Shell with Source Code

```bash
nix develop
```

### Build in Debug Mode

```bash
nix build --no-link -L 2>&1 | less
```

## Updating

### Automated via Renovate

Update pull requests are created automatically for:
- Repository version changes
- Dependency updates

### Manual

See [MAINTENANCE.md](../MAINTENANCE.md) for instructions.

## Current Limitations

- Repository hash uses `lib.fakeHash` (replaced with real hash during build)
- `node_modules` hash uses `lib.fakeHash` (replaced with real hash during build)
- Installation checks disabled (`dontInstallCheck = true`)

These limitations are due to the dynamic nature of JavaScript builds and may be refined later.

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

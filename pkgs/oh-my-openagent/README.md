# oh-my-openagent Package

Nix package for [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) — a batteries-included OpenCode plugin with multi-model orchestration, parallel background agents, and crafted LSP/AST tools.

## Description

oh-my-openagent (also published as `oh-my-opencode` on npm) is a plugin for the [OpenCode](https://github.com/anomalyco/opencode) harness. It ships 11 agents, 54+ lifecycle hooks, 5 built-in MCPs, slash commands, Team Mode, ulw-loop, ultrawork, and hash-anchored edits.

This Nix package adapts the upstream npm distribution for use in NixOS / Nix-based environments.

### Key Adaptations

1. **Source**: pulls the prebuilt `oh-my-opencode@${version}` tarball from the public npm registry (no source build required).
2. **Platform stub**: also pulls the matching `oh-my-opencode-linux-x64` tarball and re-exposes its launcher stub from `$out/lib/node_modules/...`, so the wrapper's `require.resolve()`-based platform detection succeeds.
3. **Launcher**: the upstream wrapper script `bin/oh-my-opencode.js` from the platform stub is installed as `oh-my-openagent` (and aliased as `oh-my-opencode`, `omo`, `lazycodex`, `lazycodex-ai`). It launches Bun pinned by this derivation via the `BUN_BINARY` env var.
4. **Runtime**: Bun is required (the CLI bundle `dist/cli/index.js` uses `#!/usr/bin/env bun`); Bun is added to `PATH` automatically.
5. **Musl**: glibc only. The `oh-my-opencode-linux-x64-baseline` (x86-64-v2/SSE4.2) and `*-musl*` variants are not currently supported.

## Installation

### Via Nix Flake

```bash
nix profile install github:GuillaumeASSIER/gassier-nix-pkgs#oh-my-openagent
```

### As a Dependency of Another Flake

```nix
{
  inputs.gassier-nix-pkgs.url = "github:GuillaumeASSIER/gassier-nix-pkgs";

  outputs = { gassier-nix-pkgs, ... }: {
    packages.x86_64-linux.default = gassier-nix-pkgs.packages.x86_64-linux.oh-my-openagent;
  };
}
```

## Usage

Once installed, install the plugin into OpenCode with:

```bash
oh-my-openagent install
```

The `oh-my-openagent` command is a thin launcher; the heavy lifting happens at install time, which writes per-user OpenCode configuration under `~/.config/opencode/`.

## Build Architecture

The package is composed of two npm tarballs (no source compilation):

1. **`oh-my-opencode@${version}`** (main bundle): contains the CLI source under
   `dist/cli/index.js` (a 2.7 MB Bun-compatible ESM bundle) plus agent and
   skill assets. Installed at `$out/lib/`.

2. **`oh-my-opencode-linux-x64@${version}`** (platform stub): a 6 KB launcher
   that resolves `${OMO_WRAPPER_PACKAGE_ROOT}/dist/cli/index.js` and exec's
   `bun` against it. Installed at
   `$out/lib/node_modules/oh-my-opencode-linux-x64/`.

The wrapper script `bin/oh-my-opencode.js` from the platform stub is exposed
five times in `$out/bin/`, with `OMO_WRAPPER_PACKAGE_ROOT=$out/lib` and
`BUN_BINARY=${bun}/bin/bun` set via `makeBinaryWrapper`.

## Updating

Use the standard Nix tooling from the devShell:

```bash
nix-update oh-my-openagent
```

`nix-update` will look for the latest GitHub release tag (which doubles as the npm version) and refresh both the main and the platform-specific tarball hashes.

## Known Limitations

- **License**: distributed under the upstream "Sustainable Use License v1.0"
  (non-commercial / personal / internal-business use only). Marked
  `lib.licenses.unfree`.
- **Bun runtime**: requires Bun ≥ 1.3.x; the CLI bundle uses Bun's runtime
  extensions and is not Node-compatible. The `cli-node` fallback in the
  upstream tarball is bundled with Bun's runtime headers and has the same
  requirement.
- **Platforms**: Linux only (glibc). For musl or other platforms, the
  matching `oh-my-opencode-linux-*-musl` / `oh-my-opencode-darwin-*` stub
  tarballs would need to be added.
- **AVX2 baseline**: x86_64 users on truly ancient CPUs (pre-2013, lacking
  AVX2) will need to swap in the `oh-my-opencode-linux-x64-baseline` tarball.

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

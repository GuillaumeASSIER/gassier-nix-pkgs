# gassier-nix-pkgs

Personal Nix flake repository hosting custom packages based on the latest stable versions of various software.

## Available Packages

| Package | Version | Source |
| --- | --- | --- |
| godap | 2.12.2 | [Macmod/godap](https://github.com/Macmod/godap) |
| mimo-code | 0.1.15 | [XiaomiMiMo/MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code) |
| oh-my-openagent | 5.1.10 | [code-yeongyu/oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| pi-coding-agent | 1.0.0 | [earendil-works/pi](https://github.com/earendil-works/pi) |
| murmure | 1.11.3 | [Kieierra/murmure](https://github.com/Kieirra/murmure) |
| torlink | 1.9.0 | [baairon/torlink](https://github.com/baairon/torlink) |
| opencode | 1.18.34 | [anomalyco/opencode (releases)](https://github.com/anomalyco/opencode/releases) |
| ollama | 0.35.1 | [ollama/ollama](https://github.com/ollama/ollama) |
| stoat-desktop | 1.5.4 | [stoatchat/for-desktop](https://github.com/stoatchat/for-desktop) |
| deepseek-harness | 0.2.0-rc.2 | [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) |
| oh-my-pi | 18.4.12 | [can1357/oh-my-pi (releases)](https://github.com/can1357/oh-my-pi/releases) |
| mtplvcap | 1.6.2 | [puhitaku/mtplvcap](https://github.com/puhitaku/mtplvcap) |
| higgsfield | 1.1.26 | [higgsfield-ai/cli](https://github.com/higgsfield-ai/cli) |
| msgvault | 0.20.0 | [kenn-io/msgvault](https://github.com/kenn-io/msgvault) |

## Installation and Usage

### Via Nix flake

#### Direct Installation
```bash
nix profile install github:GuillaumeASSIER/gassier-nix-pkgs
```

#### Using in a NixOS Project

Add the flake to your NixOS configuration `flake.nix`:

```nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    gassier-nix-pkgs.url = "github:GuillaumeASSIER/gassier-nix-pkgs";
  };

  outputs = { self, nixpkgs, gassier-nix-pkgs }:
    {
      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        specialArgs = {
          inherit gassier-nix-pkgs;
        };
      };
    };
}
```

Then in your `configuration.nix`:

```nix
{ config, pkgs, gassier-nix-pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gassier-nix-pkgs.packages.${pkgs.system}.mimo-code
  ];
}
```

#### Local Build

```bash
# Build the default package (godap)
nix build

# Build a specific package
nix build .#mimo-code
nix build .#godap

# Run in an ephemeral environment
nix run .#mimo-code
```

### Development Environment

To work on the flake packages:

```bash
# Enter the devshell
nix develop

# Inside the devshell you have:
# - bun, nodejs
# - nix-update, nix-prefetch-git, nix-prefetch (for hash computation & updates)
```

## Dependency Updates

This repository uses **Renovate Bot** for automatic dependency updates.

### Renovate Configuration

The `renovate.json` file configures:
- **Weekly dependency updates**
- **Semantic commits** for changes
- **Auto-merge** for certain dependency types (TypeScript types, devDeps)
- **Security alerts** with specific labels
- **Intelligent dependency grouping**

Updates are proposed as automatic pull requests that you can review before merging.

## Adding New Packages

To add a new package:

1. Create a directory `pkgs/my-package/`
2. Create the files:
   - `default.nix` - entry point
   - `package.nix` - package definition
3. Update `flake.nix` to include the new package
4. Test with `nix build .#my-package`

## Project Structure

```
.
├── flake.nix              # Flake configuration
├── renovate.json          # Renovate Bot configuration
├── pkgs/
│   ├── godap/
│   │   ├── default.nix    # Package entry point
│   │   └── package.nix    # Package definition
│   ├── mimo-code/
│   │   ├── default.nix    # Package entry point
│   │   ├── package.nix    # Package definition
│   │   └── scripts/       # Upstream helper scripts (node_modules canonicalization)
│   └── oh-my-pi/
│       ├── default.nix    # Package entry point
│       ├── package.nix    # Package definition (prebuilt release binary)
│       ├── sources.json   # Version + per-platform asset hashes
│       └── update.py      # Regenerates sources.json from the latest release
├── README.md
├── LICENSE
└── .gitignore
```

## License

This repository is licensed under [Apache 2.0](LICENSE).

## Author

- **Guillaume ASSIER**

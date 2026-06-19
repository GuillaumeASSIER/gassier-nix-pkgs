# 🚀 Quick Start

## Installation

### Prerequisites

- Nix with flakes support enabled
- Git

### Install Packages

```bash
# Direct installation
nix profile install github:GuillaumeASSIER/gassier-nix-pkgs

# Or a specific package
nix profile install github:GuillaumeASSIER/gassier-nix-pkgs#mimo-code
```

### Build Locally

```bash
git clone https://github.com/GuillaumeASSIER/gassier-nix-pkgs
cd gassier-nix-pkgs

# Build the default package
nix build

# Build a specific package
nix build .#mimo-code

# Run directly from source
nix run .#mimo-code
```

## Direnv Configuration

If you use `direnv`, it's automatic:

```bash
direnv allow
```

## Development Environment

```bash
# Enter the devshell
nix develop

# Or with direnv (automatic after direnv allow)
cd .

# You now have access to:
# - bun, nodejs
# - nix-update, nix-prefetch-git, nix-prefetch
```

## Updating Packages

See [MAINTENANCE.md](./MAINTENANCE.md) for details on:
- Updating versions
- Updating hashes
- Fixing builds

## Contact the Maintainer

- 👤 **Guillaume ASSIER**
- 📧 Open an issue on GitHub

## License

[Apache 2.0](LICENSE)

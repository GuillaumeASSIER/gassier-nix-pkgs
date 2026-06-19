# gassier-nix-pkgs

Personal Nix flake repository hosting custom packages based on the latest stable versions of various software.

## Available Packages

### mimo-code

**MiMo-Code** is a code editor based on modern web technologies, forked from popular projects.

- **Source**: [XiaomiMiMo/MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code)
- **Description**: A highly customizable code editor

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
# Build the default package
nix build

# Build a specific package
nix build .#mimo-code

# Run in an ephemeral environment
nix run
```

### Development Environment

To work on the flake packages:

```bash
# Enter the devshell
nix flake show
nix develop

# Inside the devshell
bun install
bun run build
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
│   └── mimo-code/
│       ├── default.nix    # Package entry point
│       └── package.nix    # Package definition
├── README.md
├── LICENSE
└── .gitignore
```

## License

This repository is licensed under [MIT](LICENSE).

## Author

- **Guillaume ASSIER**

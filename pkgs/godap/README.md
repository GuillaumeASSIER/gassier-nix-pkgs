# Godap Package

**Godap** is a complete terminal user interface (TUI) for LDAP written in Go.

## Features

- Full-featured LDAP client with TUI interface
- Support for various authentication methods (basic, kerberos, certificates)
- Interactive exploration of LDAP directory trees
- Powerful querying and filtering capabilities
- Modern terminal-based user experience

## Installation

### Via Nix Flake

```bash
nix profile install github:GuillaumeASSIER/gassier-nix-pkgs#godap
```

### In your flake.nix

```nix
{
  inputs = {
    gassier-nix-pkgs.url = "github:GuillaumeASSIER/gassier-nix-pkgs";
  };
  
  outputs = { self, nixpkgs, gassier-nix-pkgs }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      # ...
      specialArgs = { inherit gassier-nix-pkgs; };
    };
  };
}
```

## Usage

After installation, run godap with:

```bash
godap [options]
```

For available options and help:

```bash
godap --help
```

## Package Info

- **Version**: 2.11.0
- **License**: BSD 3-Clause
- **Source**: [Macmod/godap](https://github.com/Macmod/godap)
- **Platforms**: Linux (x86_64, aarch64), macOS (x86_64, aarch64)

## Related

- [mimo-code](../mimo-code) - AI coding agent package

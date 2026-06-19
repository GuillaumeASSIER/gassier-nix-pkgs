# Shell.nix pour développement sans direnv
# Utilisation: nix-shell

(import <nixpkgs> {}).callPackage ./flake.nix { }

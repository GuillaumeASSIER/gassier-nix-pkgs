{
  description = "Guillaume ASSIER's Nix packages flake - Custom packages for fresh software";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          mimo-code = pkgs.callPackage ./pkgs/mimo-code { };
          godap = pkgs.callPackage ./pkgs/godap { };
          default = self.packages.${system}.godap;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bun
            nodejs
            nix-update
            nix-prefetch-git
            nix-prefetch
          ];
        };
      }
    );
}

{
  description = "Guillaume ASSIER's Nix packages flake - Custom packages for fresh software";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    packages = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      godap = pkgs.callPackage ./pkgs/godap {};
      mimo-code = pkgs.callPackage ./pkgs/mimo-code {};
      oh-my-openagent = pkgs.callPackage ./pkgs/oh-my-openagent {};
      default = self.packages.${system}.godap;
    });

    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          bun
          nodejs
          nix-update
          nix-prefetch-git
          nix-prefetch
        ];
      };
    });

    formatter = forAllSystems (system: (pkgsFor system).alejandra);

    overlays.default = final: prev: {
      godap = self.packages.${final.system}.godap;
      mimo-code = self.packages.${final.system}.mimo-code;
      oh-my-openagent = self.packages.${final.system}.oh-my-openagent;
    };
  };
}

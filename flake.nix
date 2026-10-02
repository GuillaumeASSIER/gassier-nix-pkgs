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
      "aarch64-darwin"
      # x86_64-darwin dropped: nixpkgs 26.11 no longer supports it.
    ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    packages = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      godap = pkgs.callPackage ./pkgs/godap {};
      mimo-code = pkgs.callPackage ./pkgs/mimo-code {};
      torlink = pkgs.callPackage ./pkgs/torlink {};
      murmure = pkgs.callPackage ./pkgs/murmure {};
      ollama = pkgs.callPackage ./pkgs/ollama {};
      stoat-desktop = pkgs.callPackage ./pkgs/stoat-desktop {};
      deepseek-harness = pkgs.callPackage ./pkgs/deepseek-harness {};
      mtplvcap = pkgs.callPackage ./pkgs/mtplvcap {};
      higgsfield = pkgs.callPackage ./pkgs/higgsfield {};
      msgvault = pkgs.callPackage ./pkgs/msgvault {};
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
      torlink = self.packages.${final.system}.torlink;
      murmure = self.packages.${final.system}.murmure;
      ollama = self.packages.${final.system}.ollama;
      stoat-desktop = self.packages.${final.system}.stoat-desktop;
      deepseek-harness = self.packages.${final.system}.deepseek-harness;
      mtplvcap = self.packages.${final.system}.mtplvcap;
      higgsfield = self.packages.${final.system}.higgsfield;
      msgvault = self.packages.${final.system}.msgvault;
    };
  };
}

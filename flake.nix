{
  description = "Guillaume ASSIER's Nix packages flake - Custom packages for fresh software";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Optional build input of lightcraft/photocraft/filmcraft: the CJK fonts their
  # crates/text build script embeds when CRAFT_FONTS_DIR is set (same pin as
  # upstream storytold/lightcraft flake.nix).
  inputs.craft-fonts = {
    url = "github:storytold/craft-fonts/3d9ab3a132ed0eff457e424226a435a901da30d3";
    flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    craft-fonts,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      # x86_64-darwin dropped: nixpkgs 26.11 no longer supports it.
    ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    pkgsFor = system: nixpkgs.legacyPackages.${system};
    # Extra arguments shared by the Rust craft apps (storytold): the CJK fonts
    # embedded at build time.
    craftArgs = system: {craft-fonts = craft-fonts;};
  in {
    packages = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      godap = pkgs.callPackage ./pkgs/godap {};
      gitea-cli = pkgs.callPackage ./pkgs/gitea-cli {};
      mimo-code = pkgs.callPackage ./pkgs/mimo-code {};
      torlink = pkgs.callPackage ./pkgs/torlink {};
      murmure = pkgs.callPackage ./pkgs/murmure {};
      ollama = pkgs.callPackage ./pkgs/ollama {};
      stoat-desktop = pkgs.callPackage ./pkgs/stoat-desktop {};
      deepseek-harness = pkgs.callPackage ./pkgs/deepseek-harness {};
      mtplvcap = pkgs.callPackage ./pkgs/mtplvcap {};
      higgsfield = pkgs.callPackage ./pkgs/higgsfield {};
      msgvault = pkgs.callPackage ./pkgs/msgvault {};
      lightcraft = pkgs.callPackage ./pkgs/lightcraft (craftArgs system);
      photocraft = pkgs.callPackage ./pkgs/photocraft (craftArgs system);
      filmcraft = pkgs.callPackage ./pkgs/filmcraft (craftArgs system);
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
      gitea-cli = self.packages.${final.system}.gitea-cli;
      mimo-code = self.packages.${final.system}.mimo-code;
      torlink = self.packages.${final.system}.torlink;
      murmure = self.packages.${final.system}.murmure;
      ollama = self.packages.${final.system}.ollama;
      stoat-desktop = self.packages.${final.system}.stoat-desktop;
      deepseek-harness = self.packages.${final.system}.deepseek-harness;
      mtplvcap = self.packages.${final.system}.mtplvcap;
      higgsfield = self.packages.${final.system}.higgsfield;
      msgvault = self.packages.${final.system}.msgvault;
      lightcraft = self.packages.${final.system}.lightcraft;
      photocraft = self.packages.${final.system}.photocraft;
      filmcraft = self.packages.${final.system}.filmcraft;
    };
  };
}

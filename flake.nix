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
      torlink = pkgs.callPackage ./pkgs/torlink {};
      pi-coding-agent = pkgs.callPackage ./pkgs/pi-coding-agent {};
      murmure = pkgs.callPackage ./pkgs/murmure {};
      opencode = pkgs.callPackage ./pkgs/opencode {};
      ollama = pkgs.callPackage ./pkgs/ollama {};
      stoat-desktop = pkgs.callPackage ./pkgs/stoat-desktop {};
      deepseek-harness = pkgs.callPackage ./pkgs/deepseek-harness {};
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
      torlink = self.packages.${final.system}.torlink;
      pi-coding-agent = self.packages.${final.system}.pi-coding-agent;
      murmure = self.packages.${final.system}.murmure;
      opencode = self.packages.${final.system}.opencode;
      ollama = self.packages.${final.system}.ollama;
      stoat-desktop = self.packages.${final.system}.stoat-desktop;
      deepseek-harness = self.packages.${final.system}.deepseek-harness;
    };
  };
}

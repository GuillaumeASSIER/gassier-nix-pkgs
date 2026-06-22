{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule rec {
  pname = "godap";
  version = "2.11.0";

  src = fetchFromGitHub {
    owner = "Macmod";
    repo = "godap";
    rev = "v${version}";
    hash = "sha256-um9IsORwD4rPcqklEsRYI+J86R2vf7SE4RnTpaM6PnA=";
  };

  # To generate vendorHash:
  # 1. Set vendorHash to lib.fakeHash
  # 2. Build the derivation: nix build .#godap
  # 3. Copy the actual hash from the error message and replace lib.fakeHash
  vendorHash = "sha256-D5Eq2JFIEmxO/FBGON+nKtGktWPOzXfv8l5akRTpz7Q=";

  ldflags = [
    "-s"
    "-w"
  ];

  passthru = {
    updateScript = nix-update-script {};
  };

  meta = {
    description = "A complete terminal user interface (TUI) for LDAP";
    homepage = "https://github.com/Macmod/godap";
    license = lib.licenses.bsd3;
    maintainers = [
      {
        name = "Guillaume ASSIER";
        github = "GuillaumeASSIER";
      }
    ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "godap";
  };
}

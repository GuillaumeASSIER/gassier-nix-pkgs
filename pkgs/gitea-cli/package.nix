{
  lib,
  buildGo127Module,
  fetchFromGitea,
  nix-update-script,
}:
buildGo127Module rec {
  pname = "gitea-cli";
  version = "1.2.0";

  src = fetchFromGitea {
    domain = "gitea.com";
    owner = "gitea";
    repo = "cli";
    tag = "v${version}";
    hash = "sha256-ZW51bSQxm9LEksHpWt66HGg7jtu4iuz4+4a+R6ss9So=";
  };

  # To generate vendorHash:
  # 1. Set vendorHash to lib.fakeHash
  # 2. Build the derivation: nix build .#gitea-cli
  # 3. Copy the actual hash from the error message and replace lib.fakeHash
  vendorHash = "sha256-xj93kLq4uEuMymf/sdmZOz/pjfWAXbxnu9K2Xpis8PU=";

  subPackages = ["cmd/gt"];

  ldflags = [
    "-s"
    "-w"
    "-X gitea.dev/cli/internal/version.Version=${version}"
  ];

  passthru = {
    updateScript = nix-update-script {};
  };

  meta = {
    description = "Command line client for Gitea";
    longDescription = ''
      gt is the Gitea command line client, the successor of tea. It manages
      repositories, issues, pull requests, releases, Actions, packages,
      organizations, webhooks and more from the terminal.
    '';
    homepage = "https://gitea.com/gitea/cli";
    license = lib.licenses.mit;
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
    ];
    mainProgram = "gt";
  };
}

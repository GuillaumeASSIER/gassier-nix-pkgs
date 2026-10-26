{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  wl-clipboard,
  xclip,
  nix-update-script,
}:
buildNpmPackage (finalAttrs: {
  pname = "torlink";
  version = "1.10.0";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "baairon";
    repo = "torlink";
    rev = "v${finalAttrs.version}";
    hash = "sha256-PS2CYr/5XTCcmxhAxVH3MXkCKNzFiXvNhjhp8hXPbKk=";
  };

  nodejs = nodejs_22;
  npmDepsHash = "sha256-cdpgmNsc0T2q0Cu1gXo0biMaUTR8VNAIFPkx572TsQ0=";

  # ignore-scripts for ip-set broken preinstall
  npmFlags = ["--ignore-scripts"];

  postBuild = ''
    node scripts/postbuild.cjs
  '';

  postInstall = ''
    wrapProgram "$out/bin/torlnk" \
      --prefix PATH : ${lib.makeBinPath [wl-clipboard xclip]}
  '';
  passthru.updateScript = nix-update-script {};

  meta = {
    description = "A sleek, zero-setup torrent finder and downloader that lives right in your terminal.";
    homepage = "https://github.com/baairon/torlink";
    changelog = "https://github.com/baairon/torlink/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [
      {
        name = "Guillaume ASSIER";
        github = "GuillaumeASSIER";
      }
    ];
    mainProgram = "torlnk";
    platforms = lib.platforms.linux;
  };
})

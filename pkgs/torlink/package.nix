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
  version = "1.11.0";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "baairon";
    repo = "torlink";
    rev = "v${finalAttrs.version}";
    hash = "sha256-FGKq2/ZsZpFiov9P47d0JR0BvNt9sxQyZloRfTIhWWE=";
  };

  nodejs = nodejs_22;
  npmDepsHash = "sha256-hvcEWJeVPvKk0EPJrqaHoP3ZXbjWuip1G5ZZCPwNOAs=";

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

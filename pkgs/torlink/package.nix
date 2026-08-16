{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  nodejs_22,
  wl-clipboard,
  xclip,
}:
buildNpmPackage (finalAttrs: {
  pname = "torlink";
  version = "1.6.0";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "baairon";
    repo = "torlink";
    rev = "v${finalAttrs.version}";
    hash = "sha256-OE2dBGMksDFr5XYtphTda3kQqWXPETYozGXAgkjWmjU=";
  };

  nodejs = nodejs_22;
  npmDepsHash = "sha256-BobqyavnLyOigfv+Se2LTC+V+O1sjkESNaxZ+QxYFG4=";

  # ignore-scripts for ip-set broken preinstall
  npmFlags = ["--ignore-scripts"];

  # node-datachannel binary tarball
  nodeDatachannelPrebuilt = fetchurl {
    url = "https://github.com/murat-dogan/node-datachannel/releases/download/v0.32.3/node-datachannel-v0.32.3-napi-v8-linux-x64.tar.gz";
    hash = "sha256-QJKvyc1ZSjMm6xvYI9pFKyJ7dC6oIiaJss6m9zRM9no=";
  };

  postBuild = ''
    node scripts/postbuild.cjs
  '';

  postInstall = ''
    tar -xzf ${finalAttrs.nodeDatachannelPrebuilt} \
      -C "$out/lib/node_modules/torlnk/node_modules/node-datachannel"
    wrapProgram "$out/bin/torlnk" \
      --prefix PATH : ${lib.makeBinPath [wl-clipboard xclip]}
  '';

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

# higgsfield — Higgsfield AI CLI: generate images, videos, 3D assets and audio
# from the terminal (40+ models, incl. Nano Banana Pro, Veo 3.1, Kling v3.0).
#
# Upstream ships static Go executables per platform on GitHub releases, as
# `hf_<version>_<os>_<arch>.tar.gz` archives holding a single stripped `hf`
# binary. Being static, no autoPatchelf/steam-run shim is needed on NixOS.
# Version + per-platform archive hashes live in sources.json and are regenerated
# by passthru.updateScript, which follows the latest GitHub release.
{
  lib,
  stdenvNoCC,
  fetchurl,
  writeShellScriptBin,
  python3,
  git,
  installShellFiles,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}: let
  sources = lib.importJSON ./sources.json;
  inherit (sources) version;
  current = sources.platforms.${stdenvNoCC.hostPlatform.system};
in
  stdenvNoCC.mkDerivation {
    pname = "higgsfield";
    inherit version;

    src = fetchurl {
      url = "https://github.com/higgsfield-ai/cli/releases/download/v${version}/${current.asset}";
      hash = current.hash;
    };

    nativeBuildInputs = [installShellFiles];

    dontConfigure = true;
    # The tarball holds a bare `hf` file with no wrapping directory.
    sourceRoot = ".";
    # Upstream builds with -ldflags="-s -w"; re-stripping buys nothing.
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 hf $out/bin/higgsfield
      # `higgs` is the alias upstream always installs. `hf` is installed only
      # when it does not already belong to another tool (Hugging Face CLI), so
      # we deliberately omit it to keep the profile collision-free.
      ln -s higgsfield $out/bin/higgs

      runHook postInstall
    '';

    postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
      installShellCompletion --cmd higgsfield \
        --bash <($out/bin/higgsfield completion bash) \
        --fish <($out/bin/higgsfield completion fish) \
        --zsh <($out/bin/higgsfield completion zsh)
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [
      versionCheckHook
      writableTmpDirAsHomeHook
    ];
    versionCheckKeepEnvironment = ["HOME"];
    versionCheckProgram = "${placeholder "out"}/bin/higgsfield";
    versionCheckProgramArg = "--version";

    passthru.updateScript = writeShellScriptBin "update-higgsfield" ''
      set -euo pipefail
      ${lib.getExe git} rev-parse --show-toplevel >/dev/null
      exec ${lib.getExe python3} ${./update.py} "$(${lib.getExe git} rev-parse --show-toplevel)/pkgs/higgsfield/sources.json"
    '';

    meta = {
      description = "CLI to generate images, videos, 3D assets and audio with Higgsfield AI models";
      longDescription = ''
        Higgsfield CLI drives 40+ Higgsfield AI image, video, 3D and audio
        models (Nano Banana Pro, FLUX.2, Soul V2, Veo 3.1, Kling v3.0,
        Seedance 2.5, Marketing Studio, Virality Predictor, ...) from the
        terminal, including Soul ID training and workflow/preset browsing.
      '';
      homepage = "https://github.com/higgsfield-ai/cli";
      downloadPage = "https://github.com/higgsfield-ai/cli/releases";
      license = lib.licenses.mit;
      maintainers = [
        {
          name = "Guillaume ASSIER";
          github = "GuillaumeASSIER";
        }
      ];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      platforms = builtins.attrNames sources.platforms;
      mainProgram = "higgsfield";
    };
  }

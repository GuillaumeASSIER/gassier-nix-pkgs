{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_11,
  pnpmConfigHook,
  nodejs,
  node-gyp,
  python3,
  makeBinaryWrapper,
  versionCheckHook,
  git,
}: let
  pnpm = pnpm_11;
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "deepseek-harness";
    version = "0.2.1-rc.3";

    # Upstream publishes no git tags; pin the master commit this version was read from.
    src = fetchFromGitHub {
      owner = "deepseek-ai";
      repo = "deepseek-harness";
      rev = "22ddee3792402c3e70ec5f86a63c3e3e895a2f60";
      hash = "sha256-3Jf2RbMWozhUzA61Gurrb6wy1f5rnQVtZFSjT8tTvj4=";
    };

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      inherit pnpm;
      fetcherVersion = 4;
      hash = "sha256-9+YXWhs+Lsk9Qs0KrW5FuN+lccxG2G9prZBBXI9Z97o=";
    };

    nativeBuildInputs = [
      pnpm
      pnpmConfigHook
      nodejs
      node-gyp
      python3
      makeBinaryWrapper
      git
    ];

    env = {
      npm_config_nodedir = "${nodejs}";
      npm_config_offline = "true";
      # The client build stamps its artifacts with `git rev-parse HEAD`; the
      # unpacked Nix store source has no .git, so feed it the pinned commit.
      DSH_CLIENT_COMMIT_HASH = "22ddee3792402c3e70ec5f86a63c3e3e895a2f60";
      pnpm_config_offline = "true";
    };

    buildPhase = ''
      runHook preBuild

      # pnpmConfigHook installs with --ignore-scripts, so native addons are not
      # built. node-pty is required by the terminal/subprocess stack at runtime.
      NPTY_PKG=$(find node_modules/.pnpm -maxdepth 1 -type d -name 'node-pty*' | head -1)
      if [ -z "$NPTY_PKG" ]; then
        echo "deepseek-harness: node-pty not found in the pnpm store" >&2
        exit 1
      fi
      pushd "$NPTY_PKG/node_modules/node-pty"
      node-gyp rebuild
      popd

      pnpm run build:lib:host
      pnpm run build:lib:client
      pnpm run build:web

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/libexec/dsh $out/bin

      # Ship the whole workspace: built libs, apps/web/dist, config, and the
      # pnpm node_modules tree (workspace symlinks are relative and survive the
      # copy). Build-time artifacts are dropped to keep the output lean.
      rm -f tsconfig.host.tsbuildinfo tsconfig.client.tsbuildinfo
      cp -r --no-preserve=mode . $out/libexec/dsh/

      # --expose-internals lets the loader resolve bare plugin specifiers through
      # Node's internal module loader (see mountRootInclude in dsh-app-boot).
      # git: plugin specs may come from git-hosted URLs; pnpm: `dsh plugin`
      # (the documented way to create a profile) forwards to pnpm, which must
      # resolve from PATH even when not installed globally.
      makeWrapper ${nodejs}/bin/node $out/bin/dsh \
        --add-flags "--expose-internals $out/libexec/dsh/apps/cli/lib/bin.js" \
        --prefix PATH : ${lib.makeBinPath [git pnpm]}

      runHook postInstall
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [
      versionCheckHook
    ];
    versionCheckProgram = "${placeholder "out"}/bin/dsh";
    versionCheckProgramArg = "--version";

    meta = {
      description = "DeepSeek Harness (dsh) - open-source agent harness where everything is a plugin";
      homepage = "https://github.com/deepseek-ai/deepseek-harness";
      license = lib.licenses.mit;
      maintainers = [
        {
          name = "Guillaume ASSIER";
          github = "GuillaumeASSIER";
        }
      ];
      sourceProvenance = with lib.sourceTypes; [fromSource];
      platforms = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      mainProgram = "dsh";
    };
  })

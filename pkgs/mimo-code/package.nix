{
  lib,
  stdenvNoCC,
  bun,
  nodejs,
  fetchFromGitHub,
  makeBinaryWrapper,
  models-dev,
  ripgrep,
  git,
  installShellFiles,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mimo-code";
  version = "0.1.17";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "XiaomiMiMo";
    repo = "MiMo-Code";
    rev = "v${finalAttrs.version}";
    hash = "sha256-+PZ1pzYinkpHJ70eQKsS+frgCqaXKKcdfFqwxHskAL0=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src;

    impureEnvVars =
      lib.fetchers.proxyImpureEnvVars
      ++ [
        "GIT_PROXY_COMMAND"
        "SOCKS_SERVER"
      ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    env = {
      BUN_INSTALL_CACHE_DIR = "$(mktemp -d)";
    };

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install \
        --cpu=${
        if stdenvNoCC.hostPlatform.isAarch64
        then "arm64"
        else "x64"
      } \
        --os=${
        if stdenvNoCC.hostPlatform.isLinux
        then "linux"
        else "darwin"
      } \
        --ignore-scripts \
        --no-progress
      bun --bun ${./scripts/canonicalize-node-modules.ts}
      bun --bun ${./scripts/normalize-bun-binaries.ts}

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      find . -type d -name node_modules -exec cp -R --parents {} $out \;

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = "sha256-rL3SEyw0rYRSeWTRKntS/M9bC6SwcM5l+Ig5xYqsYPM=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    nodejs
    git
    installShellFiles
    makeBinaryWrapper
    models-dev
    writableTmpDirAsHomeHook
  ];

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/. .
    patchShebangs node_modules
    patchShebangs packages/*/node_modules

    runHook postConfigure
  '';

  postPatch = ''
    # packages/cli/script/build.ts refuses to run on a bun other than the one
    # pinned in package.json's `packageManager` field (strict equality);
    # nixpkgs' bun is newer than the pin, so strip the guard. The built output
    # is a bun-compiled binary and behavior does not depend on the patch level.
    sed -i '/^if (pinned && Bun.version !== pinned) {$/,/^}$/d' packages/cli/script/build.ts

  '';
  env = {
    MODELS_DEV_API_JSON = "${models-dev}/dist/_api.json";
    MIMOCODE_DISABLE_MODELS_FETCH = true;
    MIMOCODE_VERSION = finalAttrs.version;
    MIMOCODE_CHANNEL = "stable";
  };

  buildPhase = ''
    runHook preBuild

    cd ./packages/cli
    bun --bun ./script/build.ts --single --skip-install
    bun --bun ./script/schema.ts schema.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Upstream build produces dist/mimocode-{os}-{arch}/bin/mimo; expose it as `mimo-code`.
    install -Dm755 dist/*/bin/mimo $out/bin/mimo-code
    install -Dm644 schema.json $out/share/mimo-code/schema.json

    wrapProgram $out/bin/mimo-code \
      --prefix PATH : ${lib.makeBinPath [ripgrep]}

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    installShellCompletion --cmd mimo-code \
      --bash <($out/bin/mimo-code completion) \
      --zsh <(SHELL=/bin/zsh $out/bin/mimo-code completion)
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  doInstallCheck = true;
  versionCheckKeepEnvironment = [
    "HOME"
    "MIMOCODE_DISABLE_MODELS_FETCH"
  ];
  versionCheckProgramArg = "--version";

  passthru = {
    updateScript = nix-update-script {};
  };

  meta = {
    description = "MiMo-Code - AI-powered coding agent (fork of opencode)";
    homepage = "https://github.com/XiaomiMiMo/MiMo-Code";
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
    mainProgram = "mimo-code";
  };
})

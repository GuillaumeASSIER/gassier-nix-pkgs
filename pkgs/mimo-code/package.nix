{
  lib,
  stdenvNoCC,
  bun,
  fetchFromGitHub,
  makeBinaryWrapper,
  nodejs,
  nix-update-script,
  ripgrep,
  installShellFiles,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mimo-code";
  version = "0.1.1";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "XiaomiMiMo";
    repo = "MiMo-Code";
    rev = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install \
        --cpu="*" \
        --frozen-lockfile \
        --ignore-scripts \
        --no-progress \
        --os="*"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      find . -type d -name node_modules -exec cp -R --parents {} $out \;

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = lib.fakeHash;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    nodejs
    installShellFiles
    makeBinaryWrapper
    writableTmpDirAsHomeHook
  ];

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/. .
    patchShebangs node_modules

    runHook postConfigure
  '';

  env.MIMO_CODE_VERSION = finalAttrs.version;
  env.MIMO_CODE_CHANNEL = "stable";

  buildPhase = ''
    runHook preBuild

    bun install --no-save
    bun run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/mimo-code

    if [ -d "dist" ]; then
      cp -r dist/* $out/share/mimo-code/
    elif [ -d "build" ]; then
      cp -r build/* $out/share/mimo-code/
    fi

    makeWrapper ${nodejs}/bin/node \
      $out/bin/mimo-code \
      --add-flags "$out/share/mimo-code/bin/mimo-code.js" \
      --prefix PATH : ${
        lib.makeBinPath [
          ripgrep
        ]
      }

    runHook postInstall
  '';

  dontInstallCheck = true;

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "MiMo-Code - A code editor based on modern web technologies";
    homepage = "https://github.com/XiaomiMiMo/MiMo-Code";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "mimo-code";
  };
})

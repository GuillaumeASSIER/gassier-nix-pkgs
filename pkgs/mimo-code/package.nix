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
  version = "0.1.3";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "XiaomiMiMo";
    repo = "MiMo-Code";
    rev = "v${finalAttrs.version}";
    hash = "sha256-2r6CyuzASDahMqmBFrcoSEkIOASKEZmom2C3rt0e/ac=";
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
        --filter '!./' \
        --filter './packages/opencode' \
        --filter './packages/desktop' \
        --filter './packages/app' \
        --filter './packages/shared' \
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

    outputHash = "sha256-5jqls5FGnwkL3UCgIIHVwK93lVMHq1dRcK1aF514KnU=";
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
    # v0.1.3: script/index.ts hard-errors if bun < 1.3.14, but nixpkgs-unstable still ships 1.3.13.
    # Strip the version check; the script's runtime behavior is identical on patch versions.
    # TODO(mimo-code>0.1.3): remove this rewrite once nixpkgs ships bun >= 1.3.14.
    sed -i '/^if (!semver.satisfies(process.versions.bun, expectedBunVersionRange)) {$/,/^}$/d' packages/script/src/index.ts

    # v0.1.1 bug: code imports ./mimo-free which doesn't exist in the repo (fixed in main).
    # Provide a stub so the bundler resolves the import; functionality is disabled at runtime.
    # TODO(mimo-code>0.1.1): remove this stub once upstream ships mimo-free.ts in a tagged release.
    cat > packages/opencode/src/plugin/mimo-free.ts <<'STUB'
    import type { Hooks, PluginInput, Plugin as PluginInstance } from "@mimo-ai/plugin"

    export const MimoFreeAuthPlugin: PluginInstance = async (_input: PluginInput) => {
      return {} as Hooks
    }

    export const MimoFree = {
      chatBaseUrl: "",
      async verify(): Promise<{ fingerprint: string; exp: number }> {
        throw new Error("mimo-free plugin not available in this build")
      },
    }
    STUB

    # v0.1.1 bug: generate cmd imports prettier which is a root devDep, not in opencode scope.
    # Emit raw JSON instead of going through prettier; the generated spec stays valid JSON.
    # TODO(mimo-code>0.1.1): remove this rewrite once upstream moves prettier into the opencode workspace.
    cat > packages/opencode/src/cli/cmd/generate.ts <<'GEN'
    import { Server } from "../../server/server"
    import type { CommandModule } from "yargs"

    export const GenerateCommand = {
      command: "generate",
      handler: async () => {
        const specs = await Server.openapi()
        for (const item of Object.values(specs.paths)) {
          for (const method of ["get", "post", "put", "delete", "patch"] as const) {
            const operation = item[method]
            if (!operation?.operationId) continue
            // @ts-expect-error
            operation["x-codeSamples"] = [
              {
                lang: "js",
                source: [
                  `import { createOpencodeClient } from "@mimo-ai/sdk`,
                  ``,
                  `const client = createOpencodeClient()`,
                  `await client.''${operation.operationId}({`,
                  `  ...`,
                  `})`,
                ].join("\n"),
              },
            ]
          }
        }
        const raw = JSON.stringify(specs, null, 2)

        await new Promise<void>((resolve, reject) => {
          process.stdout.write(raw, (err) => {
            if (err) reject(err)
            else resolve()
          })
        })
      },
    } satisfies CommandModule
    GEN
  '';

  env = {
    MODELS_DEV_API_JSON = "${models-dev}/dist/_api.json";
    OPENCODE_DISABLE_MODELS_FETCH = true;
    OPENCODE_VERSION = finalAttrs.version;
    OPENCODE_CHANNEL = "stable";
    MIMOCODE_VERSION = finalAttrs.version;
    MIMOCODE_CHANNEL = "stable";
  };

  buildPhase = ''
    runHook preBuild

    cd ./packages/opencode
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
    "OPENCODE_DISABLE_MODELS_FETCH"
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

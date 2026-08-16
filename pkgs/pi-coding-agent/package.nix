# CHANGELOG
# 2026-07-11: Created based on nixpkgs commit 8c91a71d, bumped to 0.80.6
# 2026-07-28: Bumped to 0.82.1. pi-ai now generates its model catalog at build
#             time via a network-bound generate-models.ts; build packages/ai's
#             dist/ from the matching @earendil-works/pi-ai npm tarball instead.
# 2026-08-12: Bumped to 0.84.1. New workspaces telemetry (dep of agent), protocol
#             and client (deps of coding-agent) are compiled from source and copied
#             into node_modules alongside ai/agent/tui.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  ripgrep,
  fd,
  makeBinaryWrapper,
  stdenvNoCC,
}: let
  # Since v0.82, pi-ai no longer commits its model catalog: scripts/generate-models.ts
  # fetches it live from models.dev / OpenRouter / NVIDIA NIM / Vercel AI Gateway at
  # build time, which the sandbox can't do. The matching npm tarball (@earendil-works/pi-ai,
  # same version) ships that catalog already generated in dist/, so we drop its dist/ in
  # as the packages/ai build output and skip building pi-ai from source entirely.
  version = "0.84.2";
  piAiNpm = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${version}.tgz";
    hash = "sha256-AmJ4Wnaw6y7sWWzYp6su4j7vidLvG7EhHE8KGUTaz0E=";
  };
in
  buildNpmPackage (finalAttrs: {
    pname = "pi-coding-agent";
    inherit version;

    src = fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      tag = "v${finalAttrs.version}";
      hash = "sha256-d29ft9otYxdHRWYIAX8KMHPpppToX9ME5LbPb1rPcYo=";
    };

    npmDepsHash = "sha256-6J5Efe+6ptCuR3VZojwYPZO8BBnnZsOQ4OAeB64uYOY=";

    npmWorkspace = "packages/coding-agent";

    # Skip native module rebuild for unneeded workspaces (e.g. canvas from web-ui)
    npmRebuildFlags = ["--ignore-scripts"];

    nativeBuildInputs = [
      makeBinaryWrapper
    ];

    # pi-ai's dist/ comes from its npm tarball (see piAiNpm) instead of being built
    # from source, to avoid the network-bound generate-models step. The remaining
    # workspaces are compiled from source in dependency order (upstream's
    # build:binary order): tui/telemetry -> agent, protocol -> client -> coding-agent.
    buildPhase = ''
      runHook preBuild

      tar -xzf ${piAiNpm} -C packages/ai --strip-components=1 package/dist
      npx tsgo -p packages/tui/tsconfig.build.json
      npx tsgo -p packages/telemetry/tsconfig.build.json
      npx tsgo -p packages/protocol/tsconfig.build.json
      npx tsgo -p packages/agent/tsconfig.build.json
      npx tsgo -p packages/client/tsconfig.build.json
      npm run build --workspace=packages/coding-agent

      runHook postBuild
    '';

    # npm workspace symlinks in the output point into packages/ which
    # doesn't exist there. Replace runtime deps with built content and
    # delete the rest.
    postInstall =
      ''
        local nm="$out/lib/node_modules/pi-monorepo/node_modules"

        # Replace workspace deps needed at runtime with real copies
        for ws in @earendil-works/pi-ai:packages/ai \
                  @earendil-works/pi-agent-core:packages/agent \
                  @earendil-works/pi-telemetry:packages/telemetry \
                  @earendil-works/pi-protocol:packages/protocol \
                  @earendil-works/pi-client:packages/client \
                  @earendil-works/pi-tui:packages/tui; do
          IFS=: read -r pkg src <<< "$ws"
          rm "$nm/$pkg"
          cp -r "$src" "$nm/$pkg"
        done

        # Delete remaining workspace symlinks
        find "$nm" -type l -lname '*/packages/*' -delete

        # Clean up now-dangling .bin symlinks
        find "$nm/.bin" -xtype l -delete
      ''
      + lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
        # Remove foreign Linux binaries that make audit-tmpdir try to inspect ELF
        # RPATHs with patchelf
        rm -rf \
          "$nm/@anthropic-ai/sandbox-runtime/dist/vendor/seccomp" \
          "$nm/@anthropic-ai/sandbox-runtime/vendor/seccomp"
      '';

    postFixup = "wrapProgram $out/bin/pi --prefix PATH : ${
      lib.makeBinPath [
        ripgrep
        fd
      ]
    }";

    doInstallCheck = true;
    nativeInstallCheckInputs = [
      writableTmpDirAsHomeHook
      versionCheckHook
    ];
    versionCheckKeepEnvironment = ["HOME"];
    versionCheckProgram = "${placeholder "out"}/bin/pi";
    versionCheckProgramArg = "--version";

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://pi.dev/";
      downloadPage = "https://www.npmjs.com/package/@earendil-works/pi-coding-agent";
      changelog = "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md";
      license = lib.licenses.mit;
      maintainers = [
        {
          name = "Guillaume ASSIER";
          github = "GuillaumeASSIER";
        }
      ];
      mainProgram = "pi";
    };
  })

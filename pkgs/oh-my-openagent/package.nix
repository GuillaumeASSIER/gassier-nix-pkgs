{
  lib,
  stdenvNoCC,
  bun,
  makeBinaryWrapper,
  fetchurl,
  nix-update-script,
}: let
  pname = "oh-my-openagent";
  version = "4.13.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/oh-my-opencode/-/oh-my-opencode-${version}.tgz";
    hash = "sha256-jYVysWA86RXVty9CRxUXuejX4QPe0CNII2N57somn8w=";
  };

  platformSrc = fetchurl {
    url = "https://registry.npmjs.org/oh-my-opencode-linux-x64/-/oh-my-opencode-linux-x64-${version}.tgz";
    hash = "sha256-5zjYNnD1JyDLFofEw2qyL8ZJBocj02ueU9QkXKopq+E=";
  };
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    dontUnpack = true;

    nativeBuildInputs = [makeBinaryWrapper];

    # Provide both the main package and the platform-specific binary stub.
    # The main npm package contains the CLI source under dist/cli/; the platform
    # stub is a tiny launcher script that exec's `bun dist/cli/index.js`.
    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib $out/lib/node_modules/oh-my-opencode-linux-x64/bin
      cp ${src} $out/lib/oh-my-opencode.tgz
      cp ${platformSrc} $out/lib/oh-my-opencode-linux-x64.tgz

      tar -xzf $out/lib/oh-my-opencode.tgz -C $out/lib --strip-components=1
      mv $out/lib/oh-my-opencode.tgz $out/.oh-my-opencode.tgz
      rm -f $out/lib/bin/.gitkeep

      tar -xzf $out/lib/oh-my-opencode-linux-x64.tgz -C $out/lib/node_modules/oh-my-opencode-linux-x64 --strip-components=1
      rm -f $out/lib/node_modules/oh-my-opencode-linux-x64/bin/.gitkeep
      rm -f $out/lib/oh-my-opencode-linux-x64.tgz

      runHook postInstall
    '';

    # The platform stub relies on OMO_WRAPPER_PACKAGE_ROOT to locate the main
    # package; we point it at $out/lib so dist/cli/index.js is found.
    fixupPhase = ''
      runHook preFixup

      rm -f $out/.oh-my-opencode.tgz

      # Expose the platform stub as `oh-my-openagent` (and friends).
      # The stub launches `bun $out/lib/dist/cli/index.js ...` thanks to
      # OMO_WRAPPER_PACKAGE_ROOT. We also set BUN_BINARY so the stub uses
      # the bun pinned in this derivation.
      for bin in oh-my-opencode oh-my-openagent omo lazycodex lazycodex-ai; do
        makeWrapper \
          $out/lib/node_modules/oh-my-opencode-linux-x64/bin/oh-my-opencode.js \
          $out/bin/$bin \
          --set-default OMO_WRAPPER_PACKAGE_ROOT $out/lib \
          --set-default BUN_BINARY ${bun}/bin/bun \
          --prefix PATH : ${lib.makeBinPath [bun]}
      done

      runHook postFixup
    '';

    passthru = {
      updateScript = nix-update-script {
        extraArgs = [
          "--version-regex"
          "^v?(\\d+\\.\\d+\\.\\d+)$"
        ];
      };
    };

    meta = {
      description = "Batteries-included OpenCode plugin with multi-model orchestration, parallel background agents, and crafted LSP/AST tools";
      longDescription = ''
        oh-my-openagent (npm alias of oh-my-opencode) is a plugin for the
        OpenCode harness. It ships 11 agents, 54+ lifecycle hooks, 5 built-in
        MCPs, slash commands, Team Mode, ulw-loop, ultrawork, and hash-anchored
        edits.
      '';
      homepage = "https://github.com/code-yeongyu/oh-my-openagent";
      license = lib.licenses.unfree;
      licenseNotice = ''
        Sustainable Use License v1.0: free for non-commercial and personal
        use, or internal business purposes. Commercial redistribution or
        resale is not permitted by the upstream license. See
        https://github.com/code-yeongyu/oh-my-openagent/blob/dev/LICENSE.md
        for the full text.
      '';
      maintainers = [
        {
          name = "Guillaume ASSIER";
          github = "GuillaumeASSIER";
        }
      ];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      platforms = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      mainProgram = "oh-my-openagent";
    };
  }

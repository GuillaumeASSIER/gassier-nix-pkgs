# lightcraft — LightCraft: photo library and non-destructive raw developer (desktop app + CLI).
#
# Built from the upstream source with the vendored Cargo.lock (crates.io only, plus one git
# dep: storytold/craft-ui, handled via cargoLock). CJK/Japanese fonts from storytold/craft-fonts
# are embedded at build time via CRAFT_FONTS_DIR (as official upstream releases do); without
# them everything works but CJK glyphs are missing.
{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  wayland,
  wayland-scanner,
  libxkbcommon,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxrandr,
  vulkan-loader,
  desktop-file-utils,
  appstream,
  autoAddDriverRunpath,
  craft-fonts,
}: let
  # Version matches the upstream [workspace.package] version at this tag (v0.14.0).
  version = "0.14.0";

  isLinux = stdenv.hostPlatform.isLinux;

  appId = "ai.storyteller.lightcraft";

  # Libraries the binaries dlopen() at run time (winit loads libxkbcommon/libxcb,
  # wgpu the Vulkan loader). No RPATH points at them, hence the wrapper below.
  runtimeLibs = lib.optionals isLinux [
    libxkbcommon
    wayland
    libx11
    libxcb
    libxcursor
    libxi
    libxrandr
    vulkan-loader
  ];
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "lightcraft";
    inherit version;

    src = fetchFromGitHub {
      owner = "storytold";
      repo = "lightcraft";
      rev = "v${version}";
      hash = "sha256-v6UZTeyxzDZ1bFoYGwvwv6tF11qQNXf4ib8siGjpcHU=";
    };

    cargoLock = {
      lockFile = "${finalAttrs.src}/Cargo.lock";
      outputHashes = {
        "craft-docpath-0.1.0" = "sha256-ufVzS079k4yeeiPExB0oW/nQW5Fi8Xog0tQoDRL+26k=";
        "craft-ui-0.1.0" = "sha256-VhLeT7VLdZAIz6gR9PdFI34IJxHsGF8NE0uzFCN2vIU=";
      };
    };

    # Both binaries, as the upstream .deb/.rpm install them.
    cargoBuildFlags = [
      "--locked"
      "-p"
      "lightcraft"
      "-p"
      "lightcraft-cli"
    ];

    # Upstream `cargo xtask ci` runs `cargo test --workspace`; sandbox-incompatible tests
    # (corpus download, GPU adapter) skip themselves.
    cargoTestFlags = ["--workspace"];
    # Upstream's own flake runs the full workspace test suite, but it takes hours for
    # a ~700-crate workspace; skip during the package build (opt-in via override).
    doCheck = false;
    # One test thread: lightcraft-catalog's flock-based tests share a process-global
    # library lock and flake when parallel (see upstream nix/package.nix).
    dontUseCargoParallelTests = true;

    strictDeps = true;

    nativeBuildInputs =
      [
        pkg-config
      ]
      ++ lib.optionals isLinux [
        makeWrapper
        wayland-scanner
        desktop-file-utils
        appstream
      ]
      ++ lib.optionals (isLinux && autoAddDriverRunpath != null) [autoAddDriverRunpath];

    buildInputs = lib.optionals isLinux runtimeLibs;

    env = {
      CRAFT_FONTS_DIR = toString craft-fonts;
      # A malformed font input must fail the build rather than silently ship without glyphs.
      CRAFT_FONTS_REQUIRED = "1";
    };

    postInstall = ''
      install -Dm644 packaging/linux/${appId}.desktop $out/share/applications/${appId}.desktop
      install -Dm644 packaging/linux/${appId}.mime.xml $out/share/mime/packages/${appId}.xml
      cp -r assets/app-icon/hicolor $out/share/icons/
      install -d $out/share/metainfo
      substitute packaging/linux/${appId}.metainfo.xml.in \
        $out/share/metainfo/${appId}.metainfo.xml \
        --subst-var-by VERSION ${version} \
        --subst-var-by DATE 1970-01-01

      doc=$out/share/doc/lightcraft
      install -Dm644 -t "$doc" README.md LICENSE-MIT LICENSE-APACHE NOTICE

      desktop-file-validate $out/share/applications/${appId}.desktop
      XDG_CACHE_HOME=$TMPDIR/.cache appstreamcli validate --no-net \
        $out/share/metainfo/${appId}.metainfo.xml

      for bin in $out/bin/lightcraft $out/bin/lightcraft-cli; do
        wrapProgram "$bin" --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
      done
    '';

    passthru = {
      inherit runtimeLibs;
      updateScript = ["nix-update" "--flake" "lightcraft"];
    };

    meta = {
      description = "Photo library and non-destructive raw developer";
      longDescription = ''
        LightCraft organises a photo library and develops raw files non-destructively:
        masks, presets, colour grading, local adjustments and batch export. Ships with
        lightcraft-cli, a headless renderer, command runner and MCP server for AI agents.
      '';
      homepage = "https://getartcraft.com/apps/lightcraft";
      license = with lib.licenses; [
        mit
        asl20
      ];
      maintainers = [
        {
          name = "Guillaume ASSIER";
          github = "GuillaumeASSIER";
        }
      ];
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
      mainProgram = "lightcraft";
    };
  })

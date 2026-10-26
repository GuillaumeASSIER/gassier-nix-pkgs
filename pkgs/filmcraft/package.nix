# filmcraft — FilmCraft: non-linear video editor, clean-room reimplementation of
# Premiere Pro (desktop app + headless CLI/MCP server), built from the upstream tag.
#
# Same recipe as upstream's own release packaging (packaging/linux/package.sh):
# `cargo build --release --locked -p filmcraft -p filmcraft-cli` (no heif feature
# exists on filmcraft), CJK fonts from storytold/craft-fonts embedded via CRAFT_FONTS_DIR.
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
  alsa-lib,
  desktop-file-utils,
  appstream,
  autoAddDriverRunpath,
  craft-fonts,
}: let
  version = "0.13.0";

  isLinux = stdenv.hostPlatform.isLinux;

  appId = "ai.storyteller.filmcraft";

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
    pname = "filmcraft";
    inherit version;

    src = fetchFromGitHub {
      owner = "storytold";
      repo = "filmcraft";
      rev = "v${version}";
      hash = "sha256-mEMNK+uizVpO0szEonWxkK3M6MpGV5s0Blzt9Y5VdAg=";
    };

    cargoLock = {
      lockFile = "${finalAttrs.src}/Cargo.lock";
      outputHashes = {
        "craft-docpath-0.1.0" = "sha256-ufVzS079k4yeeiPExB0oW/nQW5Fi8Xog0tQoDRL+26k=";
        "craft-media-0.1.0" = "sha256-JfBkl7/RX3Fn1nCn0bpKsvtFhb8CVfOtkHp/ISuXc00=";
        "craft-ui-0.1.0" = "sha256-VhLeT7VLdZAIz6gR9PdFI34IJxHsGF8NE0uzFCN2vIU=";
      };
    };

    cargoBuildFlags = [
      "--locked"
      "-p"
      "filmcraft"
      "-p"
      "filmcraft-cli"
    ];

    # Upstream `cargo xtask ci` runs `cargo test --workspace`; sandbox-incompatible
    # tests (corpus download, GPU adapter) skip themselves.
    cargoTestFlags = ["--workspace"];
    # Upstream's own flake runs the full workspace test suite, but it takes hours for
    # a ~700-crate workspace; skip during the package build (opt-in via override).
    doCheck = false;
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

    buildInputs = lib.optionals isLinux (
      runtimeLibs
      ++ [
        alsa-lib
      ]
    );

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

      doc=$out/share/doc/filmcraft
      install -Dm644 -t "$doc" README.md LICENSE-MIT LICENSE-APACHE NOTICE

      desktop-file-validate $out/share/applications/${appId}.desktop
      XDG_CACHE_HOME=$TMPDIR/.cache appstreamcli validate --no-net \
        $out/share/metainfo/${appId}.metainfo.xml

      for bin in $out/bin/filmcraft $out/bin/filmcraft-cli; do
        wrapProgram "$bin" --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
      done
    '';

    passthru = {
      inherit runtimeLibs;
    };

    meta = {
      description = "Non-linear video editor; clean-room reimplementation of Premiere Pro";
      longDescription = ''
        FilmCraft edits video, color and sound natively: a Premiere-style timeline
        with three-point editing, every trim tool, Lumetri-style color grading,
        and its own Rust codecs (H.264, HEVC, ProRes, AAC). Ships with
        filmcraft-cli, a headless renderer, command runner and MCP server.
      '';
      homepage = "https://getartcraft.com/apps/filmcraft";
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
      mainProgram = "filmcraft";
    };
  })

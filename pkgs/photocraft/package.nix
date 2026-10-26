# photocraft — PhotoCraft: image editor, clean-room reimplementation of Photoshop
# (desktop app + headless CLI/MCP server), built from the upstream tag.
#
# Same recipe as upstream's own release packaging (packaging/linux/package.sh):
# `cargo build --release --locked -p photocraft -p photocraft-cli --features heif`,
# CJK fonts from storytold/craft-fonts embedded via CRAFT_FONTS_DIR.
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
  version = "0.16.0";

  isLinux = stdenv.hostPlatform.isLinux;

  appId = "ai.storyteller.photocraft";

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
    pname = "photocraft";
    inherit version;

    src = fetchFromGitHub {
      owner = "storytold";
      repo = "photocraft";
      rev = "v${version}";
      hash = "sha256-uaZmzQb4B1zZ2XrZHjHzI/uEVGdoYRFeh10GHIxzjDA=";
    };

    cargoLock = {
      lockFile = "${finalAttrs.src}/Cargo.lock";
      outputHashes = {
        "craft-docpath-0.1.0" = "sha256-ufVzS079k4yeeiPExB0oW/nQW5Fi8Xog0tQoDRL+26k=";
        "craft-jpeg-0.1.0" = "sha256-UuN/HpAyX3HdmkV46d0GY+n0yzlCmImetwlG0anzhRM=";
        "craft-print-0.1.0" = "sha256-uXP0zITi8i1JDUyc451FmZ0Pl1ZK4D0rlTJQmGFVm0I=";
        "craft-ui-0.1.0" = "sha256-VhLeT7VLdZAIz6gR9PdFI34IJxHsGF8NE0uzFCN2vIU=";
        "craft-winprint-gdi-0.1.0" = "sha256-n1pcNaBGrnvSsE5MedeSRczJOMhfmF/LGFiiDTrG1GM=";
        "winprint-0.2.1" = "sha256-wnz/VbqQ3j/x1PEq6Elxu/oSjVqdONfqQmZ31NsTIIc=";
      };
    };

    cargoBuildFlags = [
      "--locked"
      "-p"
      "photocraft"
      "-p"
      "photocraft-cli"
      "--features"
      "photocraft/heif,photocraft-cli/heif"
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

      doc=$out/share/doc/photocraft
      install -Dm644 -t "$doc" README.md LICENSE-MIT LICENSE-APACHE NOTICE

      desktop-file-validate $out/share/applications/${appId}.desktop
      XDG_CACHE_HOME=$TMPDIR/.cache appstreamcli validate --no-net \
        $out/share/metainfo/${appId}.metainfo.xml

      for bin in $out/bin/photocraft $out/bin/photocraft-cli; do
        wrapProgram "$bin" --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
      done
    '';

    passthru = {
      inherit runtimeLibs;
    };

    meta = {
      description = "Image editor; clean-room reimplementation of Photoshop";
      longDescription = ''
        PhotoCraft edits photos and layered PSD documents natively: layers, masks,
        adjustment layers, layer styles, type, vectors and brushes, rendered by a
        GPU compositor on wgpu. Ships with photocraft-cli, a headless renderer,
        command runner and MCP server for AI agents.
      '';
      homepage = "https://getartcraft.com/apps/photocraft";
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
      mainProgram = "photocraft";
    };
  })

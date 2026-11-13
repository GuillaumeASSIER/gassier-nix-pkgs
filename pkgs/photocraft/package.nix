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
  runCommand,
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
  # Version matches the upstream [workspace.package] version at this tag (v0.23.1).
  version = "0.23.1";

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
  rustPlatform.buildRustPackage (finalAttrs: let
    # Byte-identical to the lock shipped in the build tree (see postPatch), so
    # cargo's vendoring consistency check and --locked agree.
    patchedLock = runCommand "Cargo.lock" {} ''
      awk '/^\[\[patch\.unused\]\]/{f=1;next} /^\[/{f=0} !f' ${finalAttrs.src}/Cargo.lock > $out
    '';
  in {
    pname = "photocraft";
    inherit version;

    src = fetchFromGitHub {
      owner = "storytold";
      repo = "photocraft";
      rev = "v${version}";
      hash = "sha256-EhyYkRRQBvVX6CbSJX8gk4UOi/zHlE/jgC8wYUfm0ew=";
    };

    # Sync the build-time lock with the vendoring lock above: drop the
    # [patch.crates-io] entries cargo would reject against the vendored sources
    # (only crates the lock actually resolves are vendored), then install the
    # patched lock.
    postPatch = ''
      # Cargo validates every [patch.crates-io] entry against the vendored
      # patch source, but only crates the lock actually resolves are vendored.
      # Drop the entries the lock records as unused (egui_demo_lib, ...).
      while IFS= read -r unused; do
        sed -i "/^$unused = /d" Cargo.toml
      done < <(awk '/^\[\[patch\.unused\]\]/{f=1;next} /^\[/{f=0} f && /^name = /{gsub(/"/,"",$3); print $3}' Cargo.lock)

      cp ${patchedLock} Cargo.lock
    '';

    cargoLock = {
      lockFile = patchedLock;
      outputHashes = {
        "craft-docpath-0.1.0" = "sha256-BD+uNOEutI9lGz1sWcdOBC4+VgT/7HlwpWGY73ZiGxs=";
        "craft-heif-0.1.0" = "sha256-3WBe1agO+EDxC4Y+Jkp4y31rjqTQZCSL5FbUrVD2bqI=";
        "craft-pcraft-format-0.1.0" = "sha256-x3pHb9RI7FwssE7kivrhRo/0lIbrJee7Ll5Wrn96AMw=";
        "craft-winprint-gdi-0.1.0" = "sha256-HGJ4iAWJxBVXc9bSitSSOma2nqn35KgWs2ATHUyjX1E=";
        "ecolor-0.37.0" = "sha256-xzgBk6K1X/MZ8WUlIdy+r/0cf1FDkhJJuwQHZX+WY9U=";
        "winit-0.30.13" = "sha256-+67bk7cqhM5VHqROL3PeghmhKJvlPIxhU73ay45vaxw=";
        "winprint-0.2.1" = "sha256-RfhnAfv5CquYhaO9TOMg80U/ukgCySuJ0aP6SwaVT/4=";
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

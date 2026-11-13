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
  # Version matches the upstream [workspace.package] version at this tag (v0.21.1).
  version = "0.21.1";

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
  rustPlatform.buildRustPackage (finalAttrs: let
    # Byte-identical to the lock shipped in the build tree (see postPatch), so
    # cargo's vendoring consistency check and --locked agree.
    patchedLock = runCommand "Cargo.lock" {} ''
      awk '/^\[\[patch\.unused\]\]/{f=1;next} /^\[/{f=0} !f' ${finalAttrs.src}/Cargo.lock > $out
    '';
  in {
    pname = "lightcraft";
    inherit version;

    src = fetchFromGitHub {
      owner = "storytold";
      repo = "lightcraft";
      rev = "v${version}";
      hash = "sha256-2iqJCmah1bEVCxQ1VeiPWuhuHcR6U6gj6BYYUu4EcsY=";
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
        "craft-crw-0.1.0" = "sha256-Z6JTbIROXDFkdmdPmuLlo15uy7ZjxGX+EemLoz2G4gk=";
        "craft-tiff-0.1.0" = "sha256-5NqPcwqAM9U+wd4kRFJxqcdP1jADW16a5vPtXey2C0A=";
        "craft-ui-0.1.0" = "sha256-BRkWxb796qLWtF1U1EqCZFa8h1YCuoAZcXrVWMN8MEY=";
        "craft-update-0.1.0" = "sha256-BD+uNOEutI9lGz1sWcdOBC4+VgT/7HlwpWGY73ZiGxs=";
        "ecolor-0.37.0" = "sha256-xzgBk6K1X/MZ8WUlIdy+r/0cf1FDkhJJuwQHZX+WY9U=";
        "winit-0.30.13" = "sha256-+67bk7cqhM5VHqROL3PeghmhKJvlPIxhU73ay45vaxw=";
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

# stoat-desktop — Stoat for Desktop (Electron app, https://stoat.chat)
#
# Upstream ships pre-built Electron bundles per platform via GitHub releases
# (output of `electron-forge make`, MakerZIP). Building from source is not
# practical in Nix: it uses a pnpm workspace and requires the private `assets`
# git submodule at build time. We instead fetch the platform zip, repoint the
# bundled Electron binary at system libraries with autoPatchelfHook, and wrap
# it so the Chromium sandbox is disabled (its chrome-sandbox helper would need
# setuid root, which the Nix store cannot provide — upstream's own `start`
# script passes --no-sandbox too).
#
# Version bumps: `nix-update --flake stoat-desktop` updates `version` and the
# hash for the current platform. Because the source map has one hash per
# platform, re-run it on each target system (or re-hash the other three assets
# manually) so every platform stays valid.
{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  unzip,
  nix-update-script,
  # Linux runtime libraries (the bundled Electron binary's DT_NEEDED set)
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libglvnd,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  libx11,
  libxcomposite,
}: let
  version = "1.4.2";

  # Per-platform release zips. Hashes are sha256 of the GitHub release assets
  # (cross-checked against the API digests).
  sources = {
    x86_64-linux = {
      asset = "Stoat-linux-x64-${version}.zip";
      hash = "sha256-o4DdE3YH/w6uOp6rbnW0tPwLBM057wK8Uf+MME6Z56k=";
    };
    aarch64-linux = {
      asset = "Stoat-linux-arm64-${version}.zip";
      hash = "sha256-lpeCN9og6ybyEaZu2BmSM35NSctElFfN5RNMh8LLsNc=";
    };
    x86_64-darwin = {
      asset = "Stoat-darwin-x64-${version}.zip";
      hash = "sha256-YsvjByKbfCDI0rVTTtKXK8eI70SnCFWkMRwxB1hB43U=";
    };
    aarch64-darwin = {
      asset = "Stoat-darwin-arm64-${version}.zip";
      hash = "sha256-XYT5CpcKDlME9sCg8GqJJZDY8tNcjlfsqX40LrwRsfc=";
    };
  };
  current = sources.${stdenv.hostPlatform.system};

  # Brand assets (hicolor icons) live in the `assets` git submodule pinned by
  # the app at this exact commit.
  assets = fetchFromGitHub {
    owner = "stoatchat";
    repo = "assets";
    rev = "bd432f2298901a8566a092636eef0c35a3a80fbc";
    hash = "sha256-NKRByObOEN112yU588nDxteOEWRtB1OyD02S5MGgqZ0=";
  };
in
  stdenv.mkDerivation {
    pname = "stoat-desktop";
    inherit version;

    src = fetchurl {
      url = "https://github.com/stoatchat/for-desktop/releases/download/v${version}/${current.asset}";
      hash = current.hash;
    };

    nativeBuildInputs =
      [unzip makeWrapper]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        autoPatchelfHook
        copyDesktopItems
      ];

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      (lib.getLib dbus)
      expat
      glib
      gtk3
      libxkbcommon
      (lib.getLib mesa)
      nspr
      nss
      pango
      (lib.getLib systemd)
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
    ];

    desktopItems = lib.optional stdenv.hostPlatform.isLinux (makeDesktopItem {
      name = "chat.stoat.StoatDesktop";
      desktopName = "Stoat";
      genericName = "Instant Messaging";
      comment = "Open source, user-first chat platform";
      exec = "stoat-desktop";
      icon = "chat.stoat.StoatDesktop";
      terminal = false;
      categories = ["Network" "InstantMessaging"];
      startupWMClass = "stoat-desktop";
    });

    dontConfigure = true;
    dontBuild = true;
    # The release zip is a pre-built bundle, not a source tarball — unpack it
    # explicitly in the install phase.
    dontUnpack = true;

    installPhase =
      if stdenv.hostPlatform.isDarwin
      then ''
        runHook preInstall

        mkdir -p $out/Applications $out/bin
        unzip -q $src -d _unz
        cp -R _unz/Stoat.app $out/Applications/
        ln -s $out/Applications/Stoat.app/Contents/MacOS/stoat-desktop $out/bin/stoat-desktop

        runHook postInstall
      ''
      else ''
        runHook preInstall

        mkdir -p $out/lib/stoat-desktop
        unzip -q $src -d _unz
        cp -R "_unz/Stoat-linux-"*/. $out/lib/stoat-desktop/
        chmod +x $out/lib/stoat-desktop/stoat-desktop \
                 $out/lib/stoat-desktop/chrome_crashpad_handler \
                 $out/lib/stoat-desktop/chrome-sandbox

        # hicolor icons from the pinned assets submodule
        for s in 16 32 64 128 256 512; do
          install -Dm644 ${assets}/desktop/hicolor/''${s}x''${s}.png \
            $out/share/icons/hicolor/''${s}x''${s}/apps/chat.stoat.StoatDesktop.png
        done

        runHook postInstall
      '';

    # Let autoPatchelf resolve the bundled sibling libraries (libffmpeg.so,
    # libGLESv2.so, ...) which live next to the main binary rather than in any
    # buildInput.
    postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
      addAutoPatchelfSearchPath "$out/lib/stoat-desktop"
    '';

    # chrome-sandbox needs setuid root (impossible in the store); disable the
    # sandbox at launch. The real binary stays in lib/ so its $ORIGIN runpath
    # keeps resolving the sibling .so files.
    #
    # Electron dlopens the *native* EGL/GL stack (libEGL.so.1 via libglvnd,
    # dispatching to mesa) for hardware acceleration. Without it, ANGLE fails
    # to initialize and the GPU process crash-loops, freezing the app. Both
    # libglvnd (dispatcher) and mesa (driver) must be reachable.
    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      makeWrapper "$out/lib/stoat-desktop/stoat-desktop" "$out/bin/stoat-desktop" \
        --add-flags "--no-sandbox" \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libglvnd mesa.out]}
    '';

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "Stoat for Desktop – open source, user-first chat platform (Electron)";
      longDescription = ''
        Stoat is an open source, user-first chat platform. This package wraps
        the official pre-built Electron desktop application for Windows, macOS
        and Linux.
      '';
      homepage = "https://github.com/stoatchat/for-desktop";
      downloadPage = "https://github.com/stoatchat/for-desktop/releases";
      changelog = "https://github.com/stoatchat/for-desktop/releases/tag/v${version}";
      license = lib.licenses.agpl3Plus;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      maintainers = [
        {
          name = "Guillaume ASSIER";
          github = "GuillaumeASSIER";
        }
      ];
      platforms = builtins.attrNames sources;
      mainProgram = "stoat-desktop";
    };
  }

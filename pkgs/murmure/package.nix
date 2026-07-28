{
  lib,
  stdenv,
  autoPatchelfHook,
  dpkg,
  fetchurl,
  makeWrapper,
  webkitgtk_4_1,
  gtk3,
  libayatana-appindicator,
  openssl,
  gst_all_1,
  alsa-lib,
  libxtst,
  gtk-layer-shell,
  wl-clipboard,
  xdg-utils,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "murmure";
  version = "1.10.1";

  src = fetchurl {
    url = "https://github.com/Kieirra/murmure/releases/download/${finalAttrs.version}/Murmure_amd64.deb";
    hash = "sha256-BJ8htdMKee/99D/U8vayC1p6XyecFtsQu6/Z43pInPY=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs =
    [
      webkitgtk_4_1
      gtk3
      libayatana-appindicator
      openssl
      alsa-lib
      libxtst
    ]
    ++ (with gst_all_1; [
      gstreamer
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
    ]);

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out/

    runHook postInstall
  '';

  preFixup = ''
    wrapProgram $out/bin/murmure \
      --prefix PATH : ${lib.makeBinPath [wl-clipboard xdg-utils]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libayatana-appindicator gtk-layer-shell]} \
      --set GIO_EXTRA_MODULES ${gtk3}/lib/gio/modules \
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1 \
      --set GDK_BACKEND x11
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Privacy-first, open-source speech-to-text running entirely on your machine";
    homepage = "https://github.com/Kieirra/murmure";
    changelog = "https://github.com/Kieirra/murmure/blob/main/CHANGELOG.md";
    license = lib.licenses.agpl3Plus;
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    maintainers = [
      {
        name = "Guillaume ASSIER";
        github = "GuillaumeASSIER";
      }
    ];
    platforms = ["x86_64-linux"];
    mainProgram = "murmure";
  };
})

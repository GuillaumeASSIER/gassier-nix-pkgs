{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  libusb1,
  nix-update-script,
}:
buildGoModule rec {
  pname = "mtplvcap";
  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "puhitaku";
    repo = "mtplvcap";
    rev = "v${version}";
    hash = "sha256-l5H6XjcIu2EdeLAv/teyCCGDTjqPDq5vYHpHXDy+V5g=";
  };

  # To generate vendorHash:
  # 1. Set vendorHash to lib.fakeHash
  # 2. Build the derivation: nix build .#mtplvcap
  # 3. Copy the actual hash from the error message and replace lib.fakeHash
  vendorHash = "sha256-J0YW/86VD9nwQ2bq5op0sRLT5/v7W8WfVJ/mmXU2y6o=";

  # gousb and hanwen/usb both link against libusb-1.0 through pkg-config.
  nativeBuildInputs = [pkg-config];

  buildInputs = [libusb1];

  # Upstream tests do not compile at v1.6.2 (mtp/device_test.go:110 type
  # mismatch: DataTypeSelector passed as DecodeHints) and the remaining
  # tests in package mtp require a physically connected Nikon camera.
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
  ];

  passthru = {
    updateScript = nix-update-script {};
  };

  meta = {
    description = "Relays the live view of Nikon cameras as a webcam over WebSocket/MJPEG";
    homepage = "https://github.com/puhitaku/mtplvcap";
    license = lib.licenses.bsd3;
    maintainers = [
      {
        name = "Guillaume ASSIER";
        github = "GuillaumeASSIER";
      }
    ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "mtplvcap";
  };
}

{
  lib,
  buildGoModule,
  fetchFromGitHub,
  cmake,
  gitMinimal,
  apple-sdk_15,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  nix-update-script,
  stdenv,
}: let
  # Since v0.30, llama.cpp is consumed via CMake FetchContent rather than
  # vendored in-tree. Pre-stage the pin (tracks upstream's `LLAMA_CPP_VERSION`
  # file) so the FetchContent step uses our copy instead of cloning over the
  # network in the sandbox. NOTE: bump this tag/hash manually on version bumps
  # — nix-update only handles the main `src`/`vendorHash`.
  llamaCppSrc = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b11081";
    hash = "sha256-yI/oNTMzOO9Cu0xVp0YYbbgvlwTggJAPJMooDfVnMvU=";
  };
in
  buildGoModule (finalAttrs: {
    pname = "ollama";
    version = "0.34.4";

    src = fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      tag = "v${finalAttrs.version}";
      hash = "sha256-Wg1lVSJjN67TSIX75Xp/QyiuCW+HirpdJZIm92J0j6o=";
    };

    vendorHash = "sha256-45FfI47tNHBPYOBLRrwuhADCUtkjAhlFrExlEy9piMI=";
    proxyVendor = true;

    nativeBuildInputs = [
      cmake
      gitMinimal
    ];

    buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [apple-sdk_15];

    postPatch = ''
      substituteInPlace version/version.go \
        --replace-fail 0.0.0 '${finalAttrs.version}'

      # cmd/launch/*_test.go are integration tests for user-facing CLI launchers
      # that install the target binary via npm then exec it on PATH. Both
      # prerequisites are unavailable in the nix sandbox, so drop them.
      rm cmd/launch/*_test.go

      rm -r app

      # Pre-stage llama.cpp for the FetchContent step and apply Ollama's compat
      # patch. The parent passes OLLAMA_LLAMA_CPP_SKIP_COMPAT_PATCH=ON to the
      # llama/server sub-build, so it assumes the source is already prepared —
      # the caller has to apply the patch. The applier is idempotent (it skips
      # patches that `git apply --reverse --check` reports as already applied),
      # so this is safe to re-run.
      cp -r ${llamaCppSrc} $TMPDIR/llama-cpp-src
      chmod -R +w $TMPDIR/llama-cpp-src
      ( cd $TMPDIR/llama-cpp-src && \
        cmake -DPATCH_DIR=$NIX_BUILD_TOP/source/llama/compat \
          -DPATCH_LABEL=llama/compat \
          -P $NIX_BUILD_TOP/source/cmake/apply-git-patches.cmake )
    '';

    overrideModAttrs = _: _: {
      # don't run llama.cpp build in the module fetch phase
      preBuild = "";
    };

    preBuild = ''
      cmake -B build \
        -DCMAKE_SKIP_BUILD_RPATH=ON \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        -DFETCHCONTENT_SOURCE_DIR_LLAMA_CPP="$TMPDIR/llama-cpp-src" \
        -DOLLAMA_MLX_BACKENDS=""

      cmake --build build -j $NIX_BUILD_CORES
    '';

    # The llama.cpp sub-build (ExternalProject_Add) doesn't inherit the parent's
    # CMAKE_SKIP_BUILD_RPATH, so its `.so` runners end up with build-dir entries
    # in RPATH. Drop them before the forbidden-references check; $ORIGIN is
    # preserved. ELF-only — darwin builds Mach-O dylibs without this problem.
    preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      find $out/lib/ollama -type f \( -name '*.so' -o -name '*.so.*' \) \
        -exec patchelf --shrink-rpath --allowed-rpath-prefixes /nix/store {} +
    '';

    # ollama looks for runner libs in ../lib/ollama/
    # https://github.com/ollama/ollama/blob/v0.31.2/docs/development.md#library-detection
    postInstall = ''
      mkdir -p $out/lib
      cp -r build/lib/ollama $out/lib/
    '';

    ldflags = [
      "-X=github.com/ollama/ollama/version.Version=${finalAttrs.version}"
      "-X=github.com/ollama/ollama/server.mode=release"
    ];

    __darwinAllowLocalNetworking = true;

    # required for github.com/ollama/ollama/detect's tests
    sandboxProfile = lib.optionalString stdenv.hostPlatform.isDarwin ''
      (allow file-read* (subpath "/System/Library/Extensions"))
      (allow iokit-open (iokit-user-client-class "AGXDeviceUserClient"))
    '';

    checkFlags = let
      # Skip tests that require network access
      skippedTests = [
        "TestPushHandler/unauthorized_push"
        "TestPiRun_InstallAndWebSearchLifecycle"
      ];
    in ["-skip=^${builtins.concatStringsSep "$|^" skippedTests}$"];

    doInstallCheck = true;
    nativeInstallCheckInputs = [
      versionCheckHook
      writableTmpDirAsHomeHook
    ];
    versionCheckKeepEnvironment = "HOME";

    passthru = {
      updateScript = nix-update-script {};
    };

    meta = {
      description = "Get up and running with large language models locally";
      homepage = "https://github.com/ollama/ollama";
      changelog = "https://github.com/ollama/ollama/releases/tag/v${finalAttrs.version}";
      license = lib.licenses.mit;
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
      mainProgram = "ollama";
    };
  })

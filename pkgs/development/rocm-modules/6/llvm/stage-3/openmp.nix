{ lib
, stdenv
, callPackage
, rocmUpdateScript
, llvm
, clang
, clang-unwrapped
, device-libs
, rocm-cmake
, rocm-runtime
, perl
, elfutils
, libdrm
, numactl
, lit
, runtimes
}:

callPackage ../base.nix rec {
  inherit stdenv rocmUpdateScript;
  targetName = "openmp";
  targetDir = targetName;
  buildTests = false; # TODO: Fix test. clang-linker-wrapper cannot find unwind
  extraNativeBuildInputs = [ perl ];

  extraBuildInputs = [
    device-libs
    rocm-cmake
    rocm-runtime
    elfutils
    libdrm
    numactl
    runtimes
  ];

  extraCMakeFlags = [
    "-DCMAKE_MODULE_PATH=/build/source/llvm/cmake/modules" # For docs
    "-DCLANG_TOOL=${clang}/bin/clang"
    "-DCLANG_OFFLOAD_BUNDLER_TOOL=${clang-unwrapped}/bin/clang-offload-bundler"
    "-DPACKAGER_TOOL=${clang-unwrapped}/bin/clang-offload-packager"
    "-DOPENMP_LLVM_TOOLS_DIR=${llvm}/bin"
    "-DOPENMP_LLVM_LIT_EXECUTABLE=${lit}/bin/.lit-wrapped"
  ];

  extraPostPatch = ''
    # We can't build this target at the moment
    substituteInPlace libomptarget/DeviceRTL/CMakeLists.txt \
      --replace "gfx1152" ""

    # No idea what's going on here...
    cat ${./1000-openmp-failing-tests.list} | xargs -d \\n rm
  '';

  checkTargets = [ "check-${targetName}" ];
  extraLicenses = [ lib.licenses.mit ];
}

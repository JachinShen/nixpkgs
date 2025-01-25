{ lib
, stdenv
, fetchFromGitHub
, rocmUpdateScript
, cmake
, rocm-cmake
, clr
, openmp
, clang-tools-extra
, rocmtoolkit-merged
, git
, gtest
, zstd
, python3
, buildTests ? false
, buildExamples ? false
, gpuTargets ? [ ] # gpuTargets = [ "gfx803" "gfx900" "gfx1030" ... ]
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "composable_kernel";
  version = "6.3.1";

  outputs = [
    "out"
  ] ++ lib.optionals buildTests [
    "test"
  ] ++ lib.optionals buildExamples [
    "example"
  ];

  src = fetchFromGitHub {
    owner = "ROCm";
    repo = "composable_kernel";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-XIzoiFkUyQ8VsqsQFg8HVbDRdP8vZF527OpBGbBU2j0=";
  };

  nativeBuildInputs = [
    git
    cmake
    rocm-cmake
    clr
    clang-tools-extra
    zstd
    python3
  ];

  buildInputs = [ openmp ];
  
  propagatedBuildInputs = [ rocmtoolkit-merged ];

  # workaround for language HIP
  # else The HIP compiler identification is Unknown
  # Detecting HIP compiler ABI info - failed
  # Check for working HIP compiler: broken
  ROCM_PATH = "${rocmtoolkit-merged}";
  DEVICE_LIB_PATH = "${rocmtoolkit-merged}/amdgpu/bitcode";

  cmakeFlags = [
    "-DCMAKE_C_COMPILER=hipcc"
    "-DCMAKE_CXX_COMPILER=hipcc"
    # "-DCMAKE_CXX_FLAGS=-Wno-unused-parameter"
    "-DBUILD_DEV=OFF"
    "-DCK_USE_CODEGEN=ON"
    "-DCK_PARALLEL_LINK_JOBS=1"
    "-DCK_USE_ALTERNATIVE_PYTHON=${python3}/bin/python3"
    # "-DINSTANCES_ONLY=ON"
  ] ++ lib.optionals (gpuTargets != [ ]) [
    "-DGPU_TARGETS=${lib.concatStringsSep ";" gpuTargets}"
    "-DAMDGPU_TARGETS=${lib.concatStringsSep ";" gpuTargets}"
  ] ++ lib.optionals buildTests [
    "-DGOOGLETEST_DIR=${gtest.src}" # Custom linker names
  ];

  patches = [ ./cmake.patch ];

  # No flags to build selectively it seems...
  postPatch = lib.optionalString (!buildTests) ''
    substituteInPlace CMakeLists.txt \
      --replace-fail "add_subdirectory(test)" ""
    substituteInPlace codegen/CMakeLists.txt \
      --replace-fail "include(ROCMTest)" ""
  '' + lib.optionalString (!buildExamples) ''
    substituteInPlace CMakeLists.txt \
      --replace-fail "add_subdirectory(example)" ""
  '' + ''
    substituteInPlace CMakeLists.txt \
      --replace-fail "add_subdirectory(profiler)" ""
  ''
  ;

  postInstall = ''
    # zstd --rm $out/lib/libdevice_gemm_operations.a
    # zstd --rm $out/lib/libdevice_other_operations.a
    # zstd --rm $out/lib/libdevice_reduction_operations.a
  '' + lib.optionalString buildTests ''
    mkdir -p $test/bin
    mv $out/bin/test_* $test/bin
  '' + lib.optionalString buildExamples ''
    mkdir -p $example/bin
    mv $out/bin/example_* $example/bin
  '';

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  # Times out otherwise
  requiredSystemFeatures = [ "big-parallel" ];

  meta = with lib; {
    description = "Performance portable programming model for machine learning tensor operators";
    homepage = "https://github.com/ROCm/composable_kernel";
    license = with licenses; [ mit ];
    maintainers = teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor stdenv.cc.version || versionAtLeast finalAttrs.version "7.0.0";
  };
})

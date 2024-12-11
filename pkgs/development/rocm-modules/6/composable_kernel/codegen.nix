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
, buildTests ? false
, buildExamples ? false
, gpuTargets ? [ ] # gpuTargets = [ "gfx803" "gfx900" "gfx1030" ... ]
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "composable_kernel";
  version = "6.2.2";

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
    hash = "sha256-4AspBRHdon2gzf4jHB3TQlVYVciTxlqy43Ao69Wd6Ik=";
  };

  sourceRoot = "source/codegen";

  nativeBuildInputs = [
    git
    cmake
    rocm-cmake
    clr
    clang-tools-extra
    zstd
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
    "-DBUILD_TESTING=OFF"
    # "-DCMAKE_CXX_FLAGS=-Wno-unused-parameter"
    # "-DBUILD_DEV=OFF"
    # "-DCK_USE_CODEGEN=ON"
    # "-DINSTANCES_ONLY=ON"
  ] ++ lib.optionals (gpuTargets != [ ]) [
    "-DGPU_TARGETS=${lib.concatStringsSep ";" gpuTargets}"
    "-DAMDGPU_TARGETS=${lib.concatStringsSep ";" gpuTargets}"
  ] ++ lib.optionals buildTests [
    "-DGOOGLETEST_DIR=${gtest.src}" # Custom linker names
  ];

  # patches = [ ./cmake.patch ];

  # No flags to build selectively it seems...
  # postPatch = ''
  #   # mkdir -p $out/include/ck
  #   # cp -r $src/codegen/include/ck/host $out/include/ck
  # '' + lib.optionalString (!buildTests) ''
  #   substituteInPlace CMakeLists.txt \
  #     --replace "add_subdirectory(test)" ""
  # '' + lib.optionalString (!buildExamples) ''
  #   substituteInPlace CMakeLists.txt \
  #     --replace "add_subdirectory(example)" ""
  # '' + ''
  #   substituteInPlace CMakeLists.txt \
  #     --replace "add_subdirectory(profiler)" ""
  # ''
  # ;

  # postInstall = ''
  #   # zstd --rm $out/lib/libdevice_gemm_operations.a
  #   # zstd --rm $out/lib/libdevice_other_operations.a
  #   # zstd --rm $out/lib/libdevice_reduction_operations.a
  #   cp -r $src/codegen/include/ck/host $out/include/ck
  # '' + lib.optionalString buildTests ''
  #   mkdir -p $test/bin
  #   mv $out/bin/test_* $test/bin
  # '' + lib.optionalString buildExamples ''
  #   mkdir -p $example/bin
  #   mv $out/bin/example_* $example/bin
  # '';

  # passthru.updateScript = rocmUpdateScript {
  #   name = finalAttrs.pname;
  #   owner = finalAttrs.src.owner;
  #   repo = finalAttrs.src.repo;
  # };

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

{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, rocmUpdateScript
, pkg-config
, cmake
, xxd
, rocm-device-libs
, rocprofiler-register
, elfutils
, libdrm
, numactl
, valgrind
, libxml2
, libedit
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rocm-runtime";
  version = "6.3.1";

  src = fetchFromGitHub {
    owner = "ROCm";
    repo = "ROCR-Runtime";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-btpiIPV9REMvrmRSUzBIpBO6ehVIMmEmG+H8hqHDxdE=";
  };

  nativeBuildInputs = [
    pkg-config
    cmake
    xxd
  ];

  buildInputs = [
    elfutils
    libdrm
    numactl
    valgrind
    libxml2
    rocm-device-libs
    rocprofiler-register
    libedit
  ];


  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    # Manually define CMAKE_INSTALL_<DIR>
    # See: https://github.com/NixOS/nixpkgs/pull/197838
    "-DCMAKE_INSTALL_BINDIR=bin"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ];

  # patches = [
  #   (fetchpatch {
  #     name = "extend-isa-compatibility-check.patch";
  #     url = "https://salsa.debian.org/rocm-team/rocr-runtime/-/raw/076026d43bbee7f816b81fea72f984213a9ff961/debian/patches/0004-extend-isa-compatibility-check.patch";
  #     hash = "sha256-cC030zVGS4kNXwaztv5cwfXfVwOldpLGV9iYgEfPEnY=";
  #     stripLen = 1;
  #   })
  # ];

  postPatch = ''
    patchShebangs runtime/hsa-runtime/image/blit_src/create_hsaco_ascii_file.sh
    patchShebangs runtime/hsa-runtime/core/runtime/trap_handler/create_trap_handler_header.sh
    patchShebangs runtime/hsa-runtime/core/runtime/blit_shaders/create_blit_shader_header.sh

    substituteInPlace runtime/hsa-runtime/CMakeLists.txt \
      --replace-fail 'hsa/include/hsa' 'include/hsa'

    # We compile clang before rocm-device-libs, so patch it in afterwards
    # Replace object version: https://github.com/ROCm/ROCR-Runtime/issues/166 (TODO: Remove on LLVM update?)
    substituteInPlace runtime/hsa-runtime/image/blit_src/CMakeLists.txt \
      --replace-fail '-cl-denorms-are-zero' '-cl-denorms-are-zero --rocm-device-lib-path=${rocm-device-libs}/amdgcn/bitcode' \
      --replace-fail '-mcode-object-version=4' '-mcode-object-version=5'
  '';

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  meta = with lib; {
    description = "Platform runtime for ROCm";
    homepage = "https://github.com/ROCm/ROCR-Runtime";
    license = with licenses; [ ncsa ];
    maintainers = with maintainers; [ lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor stdenv.cc.version || versionAtLeast finalAttrs.version "7.0.0";
  };
})

{ lib
, stdenv
, fetchFromGitHub
, rocmUpdateScript
, clang
, pkg-config
, cmake
, fmt
, glog
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rocprofiler-register";
  version = "6.2.2";

  src = fetchFromGitHub {
    owner = "ROCm";
    repo = "rocprofiler-register";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-+G98+NeEC++zKykRazJNzxXs7S7eQedU06KHs0fnnQk=";
  };

  sourceRoot = "${finalAttrs.src.name}";

  nativeBuildInputs = [
    pkg-config
    cmake
    # clang
  ];

  buildInputs = [
    fmt
    glog
  ];

  patches = [ ./cmake.patch ];

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  meta = with lib; {
    description = "Registration library for rocprofiler";
    homepage = "https://github.com/ROCm/rocprofiler-register";
    license = with licenses; [ mit ];
    maintainers = with maintainers; teams.rocm.members;
    platforms = platforms.linux;
    # broken = versions.minor finalAttrs.version != versions.minor stdenv.cc.version || versionAtLeast finalAttrs.version "7.0.0";
  };
})

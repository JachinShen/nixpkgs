{ lib
, stdenv
, fetchFromGitHub
, rocmUpdateScript
, cmake
, clang
, libxml2
, perl
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hipify";
  version = "6.3.1";

  src = fetchFromGitHub {
    owner = "ROCm";
    repo = "HIPIFY";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-o/1LNsNtAyQcSug1gf7ujGNRRbvC33kwldrJKZi2LA0=";
  };

  nativeBuildInputs = [ cmake perl ];
  buildInputs = [ libxml2 ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "\''${LLVM_TOOLS_BINARY_DIR}/clang" "${clang}/bin/clang"
  '';

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  postInstall = ''
    chmod a+x $out/bin/*
    patchShebangs $out/bin/*
  '';

  meta = with lib; {
    description = "Convert CUDA to Portable C++ Code";
    homepage = "https://github.com/ROCm/HIPIFY";
    license = with licenses; [ mit ];
    maintainers = teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor stdenv.cc.version || versionAtLeast finalAttrs.version "7.0.0";
  };
})

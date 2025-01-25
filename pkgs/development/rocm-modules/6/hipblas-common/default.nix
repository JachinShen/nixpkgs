{ lib
, stdenv
, cmake
, rocm-cmake
, fetchFromGitHub
, rocmUpdateScript
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hipblas-common";
  version = "6.3.1";

  src = fetchFromGitHub {
    owner = "ROCm";
    repo = "hipBLAS-common";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-tvNz4ymQ1y3YSUQxAtNu2who79QzSKR+3JEevr+GDWo=";
  };

  nativeBuildInputs = [ 
    cmake
    rocm-cmake
  ];

  # dontConfigure = true;
  # dontBuild = true;

  # installPhase = ''
  #   runHook preInstall

  #   mkdir -p $out
  #   mv * $out

  #   runHook postInstall
  # '';

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  meta = with lib; {
    description = "C++ Heterogeneous-Compute Interface for Portability";
    homepage = "https://github.com/ROCm/hipBLAS-common";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor stdenv.cc.version || versionAtLeast finalAttrs.version "7.0.0";
  };
})

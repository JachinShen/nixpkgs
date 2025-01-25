{ lib
, stdenv
, fetchurl
, callPackage
, dpkg
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hsa-amd-aqlprofile-bin";
  version = "6.3.1";

  src = let
    version = finalAttrs.version;
    dotless = builtins.replaceStrings ["."] ["0"] version;
    incremental = "48";
    osRelease = "24.04";
  in fetchurl {
    url = "https://repo.radeon.com/rocm/apt/${version}/pool/main/h/hsa-amd-aqlprofile/hsa-amd-aqlprofile_1.0.0.${dotless}-${incremental}~${osRelease}_amd64.deb";
    hash = "sha256-97xEleqhioKsxDTK6vq6KylSqLzI7aI5oalljBA3KR8=";
  };

  nativeBuildInputs = [ dpkg ];
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a opt/rocm-${finalAttrs.version}/* $out
    chmod +x $out/lib/libhsa-amd-aqlprofile64.so.1.*
    chmod +x $out/lib/hsa-amd-aqlprofile/librocprofv2_att.so

    runHook postInstall
  '';

  passthru.updateScript = (callPackage ./update.nix { }) { inherit (finalAttrs) version; };

  meta = with lib; {
    description = "AQLPROFILE library for AMD HSA runtime API extension support";
    homepage = "https://rocm.docs.amd.com/en/latest/";
    license = with licenses; [ unfree ];
    maintainers = teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor stdenv.cc.version || versionAtLeast finalAttrs.version "7.0.0";
  };
})

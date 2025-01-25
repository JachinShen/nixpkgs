{ stdenv
, lsb-release
, callPackage
, rocmUpdateScript
}:

callPackage ../base.nix rec {
  inherit stdenv rocmUpdateScript;
  buildDocs = false;
  buildMan = false;
  buildTests = false;
  targetName = "hipcc";
  targetDir = "amd";

  extraPatches = [
    ./hipcc-alt-remove-isystem.patch
  ];

  extraPostPatch = ''
    cd hipcc
    substituteInPlace src/hipBin_amd.h \
      --replace "/usr/bin/lsb_release" "${lsb-release}/bin/lsb_release"
  '';

  extraPostInstall = ''
    rm -r $out/hip/bin
    ln -s $out/bin $out/hip/bin
  '';
}

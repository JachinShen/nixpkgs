{ stdenv
, lsb-release
, callPackage
, rocmUpdateScript
}:

callPackage ../base.nix rec {
  inherit stdenv rocmUpdateScript;
  buildDocs = false; # No documentation to build
  buildMan = false; # No man pages to build
  buildTests = false; # Too many errors
  targetName = "hipcc";
  targetDir = "amd";

  extraPatches = [
    # ./hipcc-cmake.patch
    ./hipcc-alt-remove-isystem.patch
  ];

  extraPostPatch = ''
    cd hipcc
    substituteInPlace src/hipBin_amd.h \
      --replace "/usr/bin/lsb_release" "${lsb-release}/bin/lsb_release"
  '';

  # extraCMakeFlags = [
  #   "-DCMAKE_CXX_EXTENSIONS=OFF"
  # ];

  extraPostInstall = ''
    rm -r $out/hip/bin
    ln -s $out/bin $out/hip/bin
  '';
  # targetRuntimes = [ targetName ];
  # checkTargets = [ "check-${targetName}" ];
}

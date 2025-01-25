{ stdenv
, callPackage
, rocmUpdateScript
}:

callPackage ../base.nix rec {
  inherit stdenv rocmUpdateScript;
  buildDocs = false;
  buildMan = false;
  buildTests = false;
  targetName = "device-libs";
  targetDir = "amd";
  extraPatches = [ ./device-libs-cmake.patch ];
  extraPostPatch = ''
    cd device-libs
  '';
}

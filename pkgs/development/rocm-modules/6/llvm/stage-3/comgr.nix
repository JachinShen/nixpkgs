{ stdenv
, callPackage
, rocmUpdateScript
, device-libs
}:

callPackage ../base.nix rec {
  inherit stdenv rocmUpdateScript;
  buildDocs = false;
  buildMan = false;
  buildTests = false; 
  targetName = "comgr";
  targetDir = "amd";
  extraPostPatch = ''
    cd comgr
  '';

  extraBuildInputs = [
    device-libs
  ];
}

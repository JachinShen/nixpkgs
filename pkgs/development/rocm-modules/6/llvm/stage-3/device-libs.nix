{ stdenv
, callPackage
, llvmPackages
, rocmUpdateScript
}:

callPackage ../base.nix rec {
  inherit stdenv rocmUpdateScript;
  buildDocs = false; # No documentation to build
  buildMan = false; # No man pages to build
  buildTests = false; # Too many errors
  targetName = "device-libs";
  targetDir = "amd";
  extraPatches = [ ./device-libs-cmake.patch ];
  extraPostPatch = ''
    cd device-libs
  '';
  extraBuildInputs = [ llvmPackages.libllvm ];
  # targetRuntimes = [ targetName ];
  # checkTargets = [ "check-${targetName}" ];
}

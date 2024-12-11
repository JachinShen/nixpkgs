{ lib
, stdenv
, callPackage
, rocmUpdateScript
, llvm
}:

callPackage ../base.nix rec {
  inherit stdenv rocmUpdateScript;
  buildDocs = false;
  buildMan = false;
  buildTests = false;
  targetName = "llvm_toolchain";
  targetProjects = [
    "llvm"
    "clang"
    "lld"
    # "compiler-rt"
    # "clang-tools-extra"
  ];

  # targetRuntimes = [
  #   "libcxx"
  #   "libcxxabi"
  #   "libunwind"
  # ];

  extraCMakeFlags = [
    # "-DCMAKE_C_COMPILER=${stdenv.cc}/bin/clang"
    # "-DCMAKE_CXX_COMPILER=${stdenv.cc}/bin/clang++"
    "-DCLANG_ENABLE_AMDCLANG=ON"
    # "-DLIBCXX_ENABLE_STATIC=ON"
    # "-DLIBCXXABI_ENABLE_STATIC=ON"
    "-DCLANG_DEFAULT_LINKER=lld"
    "-DLLVM_ENABLE_BINDINGS=OFF"
    "-DLLVM_LINK_LLVM_DYLIB=OFF"
    "-DLLVM_BUILD_LLVM_DYLIB=OFF"
    "-DLLVM_ENABLE_ASSERTIONS=ON"
  ];

  extraLicenses = [ lib.licenses.mit ];
}

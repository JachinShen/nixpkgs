{ stdenv
, gcc13Stdenv
, llvmPackages
, callPackage
, rocmUpdateScript
, wrapBintoolsWith
, overrideCC
# , clr
, rocm-cmake
, rocm-runtime
}:

let
  ## Stage 1 ##
  # Projects
  llvm = callPackage ./stage-1/llvm.nix { inherit rocmUpdateScript; stdenv = stdenv; };
  clang-unwrapped = callPackage ./stage-1/clang-unwrapped.nix { inherit rocmUpdateScript llvm; stdenv = stdenv; };
  lld = callPackage ./stage-1/lld.nix { inherit rocmUpdateScript llvm; stdenv = stdenv; };

  # Runtimes
  runtimes = callPackage ./stage-1/runtimes.nix { inherit rocmUpdateScript llvm; stdenv = llvmPackages.stdenv; };

  ## Stage 2 ##
  # Helpers
  bintools-unwrapped = callPackage ./stage-2/bintools-unwrapped.nix { inherit llvm lld; };
  llvm-bintools = wrapBintoolsWith { bintools = bintools-unwrapped; };
in rec {
  inherit
  llvm
  clang-unwrapped
  lld
  runtimes
  llvm-bintools
  ;

  ## Stage 3 ##
  # Helpers
  clang = callPackage ./stage-3/clang.nix { inherit llvm lld clang-unwrapped llvm-bintools runtimes; useLLD = true; stdenv = gcc13Stdenv; };
  rocmClangStdenv = overrideCC gcc13Stdenv clang;

  clangNoLLD = callPackage ./stage-3/clang.nix { inherit llvm lld clang-unwrapped llvm-bintools runtimes; useLLD = false; stdenv = gcc13Stdenv; };
  rocmClangNoLLDStdenv = overrideCC gcc13Stdenv clangNoLLD;

  # Runtimes
  # pstl = callPackage ./stage-3/pstl.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };

  # amd
  device-libs = callPackage ./stage-3/device-libs.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };
  comgr = callPackage ./stage-3/comgr.nix { inherit rocmUpdateScript device-libs; stdenv = rocmClangStdenv; };
  hipcc = callPackage ./stage-3/hipcc.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };

  # Projects
  clang-tools-extra = callPackage ./stage-3/clang-tools-extra.nix { inherit rocmUpdateScript llvm clang-unwrapped; stdenv = stdenv; };
  # libclc = callPackage ./stage-3/libclc.nix { inherit rocmUpdateScript llvm clang; stdenv = rocmClangStdenv; };
  # lldb = callPackage ./stage-3/lldb.nix { inherit rocmUpdateScript clang; stdenv = rocmClangStdenv; };
  # mlir = callPackage ./stage-3/mlir.nix { inherit rocmUpdateScript clr; stdenv = rocmClangStdenv; };
  # polly = callPackage ./stage-3/polly.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };
  # flang = callPackage ./stage-3/flang.nix { inherit rocmUpdateScript clang-unwrapped mlir; stdenv = rocmClangStdenv; };
  openmp = callPackage ./stage-3/openmp.nix { inherit rocmUpdateScript llvm clang-unwrapped clang device-libs rocm-cmake rocm-runtime runtimes; stdenv = rocmClangStdenv; };
}

{ stdenv # FIXME: Try changing back to this with a new ROCm release https://github.com/NixOS/nixpkgs/issues/271943
, gcc14Stdenv
, llvmPackages
, callPackage
, rocmUpdateScript
, wrapBintoolsWith
, overrideCC
, rocm-device-libs
, rocm-runtime
, rocm-thunk
, clr
}:

let
  ## Stage 1 ##
  # Projects
  # llvm_toolchain = callPackage ./stage-1/llvm-toolchain.nix { inherit rocmUpdateScript; stdenv = llvmPackages.stdenv; };
  llvm = callPackage ./stage-1/llvm.nix { inherit rocmUpdateScript; stdenv = gcc14Stdenv; };
  clang-unwrapped = callPackage ./stage-1/clang-unwrapped.nix { inherit rocmUpdateScript llvm; stdenv = gcc14Stdenv; };
  lld = callPackage ./stage-1/lld.nix { inherit rocmUpdateScript llvm; stdenv = gcc14Stdenv; };
  # clang-tools-extra = callPackage ./stage-1/clang-tools-extra.nix { inherit rocmUpdateScript llvm clang-unwrapped; stdenv = llvmPackages.stdenv; };

  # Runtimes
  # runtimes = callPackage ./stage-1/runtimes.nix { inherit rocmUpdateScript llvm; stdenv = llvmPackages.stdenv; };

  ## Stage 2 ##
  # Helpers
  bintools-unwrapped = callPackage ./stage-2/bintools-unwrapped.nix { inherit llvm lld; };
  bintools = wrapBintoolsWith { bintools = bintools-unwrapped; };
  # rStdenv = callPackage ./stage-2/rstdenv.nix { inherit llvm clang-unwrapped lld runtimes bintools; stdenv = stdenv; };
in rec {
  inherit
  # llvm_toolchain
  llvm
  clang-unwrapped
  lld
  # clang-tools-extra
  # runtimes
  bintools
  # rStdenv
  ;

  # Runtimes
  # libc = callPackage ./stage-2/libc.nix { inherit rocmUpdateScript; stdenv = rStdenv;};
  libunwind = callPackage ./stage-2/libunwind.nix { inherit rocmUpdateScript; stdenv = llvmPackages.stdenv; };
  libcxxabi = callPackage ./stage-2/libcxxabi.nix { inherit rocmUpdateScript; stdenv = llvmPackages.stdenv; };
  libcxx = callPackage ./stage-2/libcxx.nix { inherit rocmUpdateScript; stdenv = llvmPackages.stdenv; };
  compiler-rt = callPackage ./stage-2/compiler-rt.nix { inherit rocmUpdateScript llvm; stdenv = llvmPackages.stdenv; };

  ## Stage 3 ##
  # Helpers
  clang = callPackage ./stage-3/clang.nix { inherit llvm lld clang-unwrapped bintools libunwind libcxxabi libcxx compiler-rt ; stdenv = stdenv; };
  rocmClangStdenv = overrideCC stdenv clang;

  # Projects
  clang-tools-extra = callPackage ./stage-3/clang-tools-extra.nix { inherit rocmUpdateScript llvm clang-unwrapped; stdenv = rocmClangStdenv; };
  libclc = callPackage ./stage-3/libclc.nix { inherit rocmUpdateScript llvm clang; stdenv = rocmClangStdenv; };
  lldb = callPackage ./stage-3/lldb.nix { inherit rocmUpdateScript clang; stdenv = rocmClangStdenv; };
  mlir = callPackage ./stage-3/mlir.nix { inherit rocmUpdateScript clr; stdenv = rocmClangStdenv; };
  polly = callPackage ./stage-3/polly.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };
  flang = callPackage ./stage-3/flang.nix { inherit rocmUpdateScript clang-unwrapped mlir; stdenv = rocmClangStdenv; };
  openmp = callPackage ./stage-3/openmp.nix { inherit rocmUpdateScript llvm clang-unwrapped clang rocm-device-libs rocm-runtime rocm-thunk; stdenv = rocmClangStdenv; };

  # Runtimes
  pstl = callPackage ./stage-3/pstl.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };

  # amd
  device-libs = callPackage ./stage-3/device-libs.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };
  comgr = callPackage ./stage-3/comgr.nix { inherit rocmUpdateScript device-libs; stdenv = rocmClangStdenv; };
  hipcc = callPackage ./stage-3/hipcc.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };
}

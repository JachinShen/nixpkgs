{ stdenv
, wrapCCWith
, llvm
, lld
, clang-unwrapped
, bintools
, runtimes
# , libc
# , libunwind
# , libcxxabi
# , libcxx
# , compiler-rt
}:

wrapCCWith rec {
  # inherit libcxx bintools;
  libcxx = runtimes;
  # inherit bintools;

  # We do this to avoid HIP pathing problems, and mimic a monolithic install
  # cc = stdenv.mkDerivation (finalAttrs: {
  #   inherit (clang-unwrapped) version;
  #   pname = "rocm-llvm-clang";
  #   dontUnpack = true;

  #   # https://github.com/ROCm/llvm-project/blob/rocm-6.2.2/cmake/Modules/GetClangResourceDir.cmake
  #   # rocm-6.2.2 use CLANG_MAJOR_VERSION
  #   installPhase = ''
  #     runHook preInstall

  #     clang_version=`${clang-unwrapped}/bin/clang -v 2>&1 | grep "clang version " | grep -E -o "[0-9.-]+" | grep -E -o "^[0-9]+"`
  #     mkdir -p $out/{bin,include/c++/v1,lib/{cmake,clang/$clang_version/{include,lib}},libexec,share}

  #     for path in ${llvm} ${clang-unwrapped} ${lld} ${libunwind} ${libcxxabi} ${libcxx} ${compiler-rt} ; do
  #       cp -as $path/* $out
  #       chmod +w $out/{*,include/c++/v1,lib/{clang/$clang_version/include,cmake}}
  #       rm -f $out/lib/libc++.so
  #     done

  #     # ln -s $out/lib/libc++.so.1.0 $out/lib/libc++.so

  #     ln -s $out/lib/* $out/lib/clang/$clang_version/lib
  #     ln -sf $out/include/* $out/lib/clang/$clang_version/include

  #     runHook postInstall
  #   '';

  #   passthru.isClang = true;
  # });
  # gccForLibs = stdenv.cc.cc;
  # gccForLibs = null;
  cc = clang-unwrapped;

  extraPackages = [
    llvm
    lld
    # libc
    # libunwind
    # libcxx
    # libcxxabi
    # compiler-rt
    runtimes
  ];

  nixSupport.cc-cflags = [
    "-resource-dir=$out/resource-root"
    "-fuse-ld=lld"
    "-rtlib=compiler-rt"
    # "-B${compiler-rt}/lib"
    # "-B${runtimes}/lib"
    "-unwindlib=libunwind"
    "-Wno-unused-command-line-argument"
    "-lunwind"
  ];

  # nixSupport.cc-ldflags = [
  #   "-L${runtimes}/lib"
  # ];

  extraBuildCommands = ''
    clang_version=`${cc}/bin/clang -v 2>&1 | grep "clang version " | grep -E -o "[0-9.-]+" | grep -E -o "^[0-9]+"`
    mkdir -p $out/resource-root
    ln -s ${cc}/lib/clang/$clang_version/include $out/resource-root
    ln -s ${runtimes}/{share,lib} $out/resource-root

    cp -as ${llvm}/bin/llc $out/bin

    # Not sure why, but hardening seems to make things break
    echo "" > $out/nix-support/add-hardening.sh

    # GPU compilation uses builtin `lld`
    substituteInPlace $out/bin/{clang,clang++} \
      --replace-fail "-MM) dontLink=1 ;;" "-MM | --cuda-device-only) dontLink=1 ;;''\n--cuda-host-only | --cuda-compile-host-device) dontLink=0 ;;"
  '';
}

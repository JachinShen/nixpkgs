{ stdenv
, wrapCCWith
, llvm
, lld
, clang-unwrapped
, llvm-bintools
, runtimes
, useLLD ? false
}:

wrapCCWith rec {
  libcxx = runtimes;
  bintools = if useLLD then llvm-bintools else stdenv.cc.bintools;
  gccForLibs = stdenv.cc.cc;

  cc = clang-unwrapped;

  extraPackages = [
    llvm
    lld
    runtimes
  ];

  nixSupport.cc-cflags = if useLLD then [
    "-resource-dir=$out/resource-root"
    "-fuse-ld=lld"
    "-rtlib=compiler-rt"
    "-unwindlib=libunwind"
    "-Wno-unused-command-line-argument"
    "-lunwind"
  ] else [
    "-resource-dir=$out/resource-root"
    "-rtlib=compiler-rt"
    "-unwindlib=libunwind"
    "-Wno-unused-command-line-argument"
    "-lunwind"
  ];

  extraBuildCommands = ''
    clang_version=`${cc}/bin/clang -v 2>&1 | grep "clang version " | grep -E -o "[0-9.-]+" | grep -E -o "^[0-9]+"`
    mkdir -p $out/resource-root
    ln -s ${cc}/lib/clang/$clang_version/include $out/resource-root
    ln -s ${runtimes}/{share,lib} $out/resource-root

    cp -as ${llvm}/bin/llc $out/bin
    cp -as ${cc}/bin/{clang-cpp,clang-18,clang-cl,flang} $out/bin

    # Not sure why, but hardening seems to make things break
    echo "" > $out/nix-support/add-hardening.sh

    # GPU compilation uses builtin `lld`
    substituteInPlace $out/bin/{clang,clang++} \
      --replace-fail "-MM) dontLink=1 ;;" "-MM | --cuda-device-only) dontLink=1 ;;''\n--cuda-host-only | --cuda-compile-host-device) dontLink=0 ;;"

    substituteInPlace $out/nix-support/cc-cflags \
      --replace-fail " -nostdlibinc" ""
  '';
}

{ runCommandLocal,
  composable_kernel_build,
  composable_kernel_codegen,
  zstd
}:
let
  ck = composable_kernel_build;
  cg = composable_kernel_codegen;
in runCommandLocal "unpack-${ck.name}" {
    nativeBuildInputs = [ zstd ];
    meta = ck.meta;
  } ''
    mkdir -p $out
    cp -r --no-preserve=mode ${ck}/* $out
    cp -r --no-preserve=mode ${cg}/* $out
    # cp -r --no-preserve=mode /home/jachinshen/Documents/nixpkgs/source_ck/include/ck/tensor_operation $out/include/ck
    # zstd -dv --rm $out/lib/libdevice_operations.a.zst -o $out/lib/libdevice_operations.a
    substituteInPlace $out/include/ck/tensor_operation/gpu/device/device_base.hpp \
      --replace-fail '#include "ck/stream_config.hpp"' '#include "ck/ck.hpp"
#include "ck/stream_config.hpp"'

    substituteInPlace $out/lib/cmake/composable_kernel/*.cmake \
      --replace-warn "${ck}" "$out"
  ''

{ runCommandLocal,
  composable_kernel_build,
  # composable_kernel_codegen,
  zstd
}:
let
  ck = composable_kernel_build;
  # cg = composable_kernel_codegen;
in runCommandLocal "unpack-${ck.name}" {
    nativeBuildInputs = [ zstd ];
    meta = ck.meta;
  } ''
    mkdir -p $out
    cp -r --no-preserve=mode ${ck}/* $out
    # zstd -dv --rm $out/lib/libdevice_operations.a.zst -o $out/lib/libdevice_operations.a
    substituteInPlace $out/include/ck/tensor_operation/gpu/device/device_base.hpp \
      --replace-fail '#include "ck/stream_config.hpp"' '#include "ck/ck.hpp"
#include "ck/stream_config.hpp"'

    substituteInPlace $out/lib/cmake/composable_kernel/*.cmake \
      --replace-warn "${ck}" "$out"
  ''

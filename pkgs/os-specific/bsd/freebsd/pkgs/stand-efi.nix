{
  lib,
  stdenv,
  mkDerivation,
  include,
  buildPackages,
  freebsd-lib,
  vtfontcvt,
}:
let
  hostArchBsd = freebsd-lib.mkBsdArch stdenv;
in
mkDerivation {
  path = "stand/efi";
  extraPaths = [
    "contrib/bzip2"
    "contrib/llvm-project/compiler-rt/lib/builtins"
    "contrib/lua"
    "contrib/pnglite"
    "contrib/terminus"
    "lib/libc"
    "lib/liblua"
    "libexec/flua"
    "lib/flua"
    "stand"
    "sys"
  ] ++ lib.optionals stdenv.hostPlatform.isAarch64 [
    "lib/libfdt"
  ];
  extraNativeBuildInputs = [ vtfontcvt ];

  makeFlags = [
    "STRIP=-s" # flag to install, not command
    "MK_MAN=no"
    "MK_TESTS=no"
    "OBJCOPY=${lib.getBin buildPackages.binutils-unwrapped}/bin/${buildPackages.binutils-unwrapped.targetPrefix}objcopy"
  ] ++ lib.optional (!stdenv.hostPlatform.isFreeBSD) "MK_WERROR=no";

  hardeningDisable = [ "stackprotector" ];

  preBuild = ''
    # # stand/defs.mk tries -Iinclude, which isn't in our filtered source
    NIX_CFLAGS_COMPILE+=" -I${include}/include -I$BSDSRCDIR/sys/sys -I$BSDSRCDIR/sys/${hostArchBsd}/include"
    export NIX_CFLAGS_COMPILE

    # Dependencies are listed in stand/Makefile, we don't use that so build them manually
    make -C $BSDSRCDIR/stand/libsa $makeFlags
    make -C $BSDSRCDIR/stand/ficl $makeFlags
    make -C $BSDSRCDIR/stand/liblua $makeFlags
  '' + lib.optionalString stdenv.hostPlatform.isAarch64 ''
    make -C $BSDSRCDIR/stand/fdt $makeFlags
  '';

  postPatch = ''
    sed -E -i -e 's|/bin/pwd|${buildPackages.coreutils}/bin/pwd|' $BSDSRCDIR/stand/defs.mk
  '';

  postInstall = ''
    mkdir -p $out/bin/lua
    cp $BSDSRCDIR/stand/lua/*.lua $out/bin/lua
    cp -r $BSDSRCDIR/stand/defaults $out/bin/defaults
  '';

  meta.platforms = lib.platforms.freebsd;
}

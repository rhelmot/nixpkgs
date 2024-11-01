{ mkDerivation, stdenv, pkgsBuildTarget }:
assert stdenv.hostPlatform.parsed.cpu.name == "x86_64";  # TODO
mkDerivation {
  path = "sys/arch/amd64/stand";
  extraPaths = [ "sys" ];

  # gcc compat
  postPatch = ''
    find $BSDSRCDIR -name Makefile -print0 | xargs -0 sed -E -i -e 's/-nopie/-no-pie/g'
    substituteInPlace $BSDSRCDIR/sys/arch/*/stand/boot/check-boot.pl --replace-fail /usr/bin/objdump objdump
    substituteInPlace $BSDSRCDIR/sys/arch/*/stand/Makefile --replace-quiet " boot " " " --replace-quiet " fdboot " " "
    substituteInPlace $BSDSRCDIR/sys/arch/amd64/stand/efiboot/conf.c --replace-fail 'debug = 0' 'debug = 1'
  '';

  # expects to be able to use unprefixed programs
  # needs gnu assembler + objdump + objcopy
  # this is really not designed for cross...
  preBuild = ''
    mkdir $TMP/bin
    export PATH=$TMP/bin:$PATH
    ln -s ${stdenv.cc}/bin/${stdenv.cc.targetPrefix}size $TMP/bin/size
    ln -s ${pkgsBuildTarget.binutils}/bin/${pkgsBuildTarget.binutils.targetPrefix}as $TMP/bin/as
    ln -s ${pkgsBuildTarget.binutils}/bin/${pkgsBuildTarget.binutils.targetPrefix}objdump $TMP/bin/objdump
    ln -s ${pkgsBuildTarget.binutils}/bin/${pkgsBuildTarget.binutils.targetPrefix}objcopy $TMP/bin/objcopy
    ln -s ${pkgsBuildTarget.binutils}/bin/${pkgsBuildTarget.binutils.targetPrefix}objcopy $TMP/bin/

    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-pointer-sign -DEFI_DEBUG -DBIOS_DEBUG -DCOMPAT_UFS "
    NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -DDEBUG" make $makeFlags -C $BSDSRCDIR/sys/arch/amd64/stand/efiboot/bootx64 dev_i386.o
  '';
}

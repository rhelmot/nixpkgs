{ mkDerivation, buildPackages, lib }:
mkDerivation {
  path = "sys/dev/microcode";
  extraPaths = [ "sys/dev" ];

  postPatch = ''
    substituteInPlace $BSDSRCDIR/sys/dev/microcode/*/Makefile --replace-quiet "/etc" "\''${FWDIR}"
  '';

  # build some host programs - named build.c
  preBuild = ''
    mkdir $TMP/include
    mkdir $TMP/include/machine
    mkdir $TMP/include/sys

    cp -r $BSDSRCDIR/sys/dev $TMP/include/dev

    echo '#include <stdint.h>' >>$TMP/include/sys/types.h
    echo '#include_next <sys/types.h>' >>$TMP/include/sys/types.h

    echo '#include_next <err.h>' >>$TMP/include/err.h
    echo '#define errc(a, b, c, ...) (void)0' >>$TMP/include/err.h

    echo '#include_next <sys/cdefs.h>' >>$TMP/include/sys/cdefs.h
    echo '#define     __aligned(x)    __attribute__((__aligned__(x)))' >>$TMP/include/sys/cdefs.h
    echo '#define     __packed        __attribute__((__packed__))' >>$TMP/include/sys/cdefs.h

    find . -name build.c -print0 | xargs -0 -I{} bash -c 'cd $(dirname {}) && pwd && touch build.o && ${buildPackages.stdenv.cc}/bin/cc build.c -I$TMP/include -I${lib.getDev buildPackages.zlib}/include -L${lib.getLib buildPackages.zlib}/lib -lz -o build'
  '';

  # dunno why build misses this one but install wants it
  postBuild = ''
    pushd $BSDSRCDIR/sys/dev/microcode/myx
    ./build
    popd
  '';

  preInstall = ''
    export makeFlags="$makeFlags FWDIR=$out/etc"
  '';
}

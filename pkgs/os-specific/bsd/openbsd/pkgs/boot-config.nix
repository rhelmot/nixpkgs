{ mkDerivation, lib, flex, byacc }:
mkDerivation {
  path = "usr.sbin/config";

  extraNativeBuildInputs = [ flex byacc ];

  postPatch = ''
    rm $BSDSRCDIR/usr.sbin/config/ukc.c
    rm $BSDSRCDIR/usr.sbin/config/ukcutil.c
    rm $BSDSRCDIR/usr.sbin/config/cmd.c
    rm $BSDSRCDIR/usr.sbin/config/exec_elf.c
  '';

  buildPhase = ''
    mkdir $TMP/include
    mkdir $TMP/include/sys

    echo '#include_next <sys/types.h>' >>$TMP/include/sys/types.h
    echo '#define O_EXLOCK 0' >>$TMP/include/sys/types.h
    echo '#include <sys/sysmacros.h>' >>$TMP/include/sys/types.h
    echo '#define pledge(a, b) 0' >>$TMP/include/sys/types.h
    echo '#define errc(a, b, c, ...) (void)0' >>$TMP/include/sys/types.h


    for f in *.l; do flex $f; done
    for f in *.y; do yacc -H ''${f%.y}.h $f; done
    for f in *.c; do $CC -I$TMP/include -DMAKE_BOOTSTRAP -c $f; done
    $CC *.o -o config
  '';

  meta.platforms = lib.platforms.linux;
}

{ mkDerivation, lib, flex, byacc }:
mkDerivation {
  path = "usr.bin/ctags";

  extraNativeBuildInputs = [ flex byacc ];

  buildPhase = ''
    mkdir $TMP/include
    mkdir $TMP/include/sys

    echo '#include_next <sys/types.h>' >>$TMP/include/sys/types.h
    echo '#define pledge(a, b) 0' >>$TMP/include/sys/types.h

    echo '#include <dirent.h>' >>$TMP/include/sys/dirent.h

    for f in *.l; do flex $f; done
    for f in *.y; do yacc -H ''${f%.y}.h $f; done
    for f in *.c; do $CC -I$TMP/include -DMAKE_BOOTSTRAP -c $f; done
    $CC *.o -o ctags
  '';

  meta.platforms = lib.platforms.linux;
}

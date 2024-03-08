{ mkDerivation, ... }:
mkDerivation {
  path = "lib/atf";
  extraPaths = [ "contrib/atf" ];

  postPatch = ''
    sed -E -i -e "/include/i #include <stddef.h>" $BSDSRCDIR/contrib/atf/atf-c/*.c $BSDSRCDIR/contrib/atf/atf-c/*/*.c $BSDSRCDIR/contrib/atf/atf-c++/*.cpp $BSDSRCDIR/contrib/atf/atf-c++/*/*.cpp
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -D_VA_LIST -D_VA_LIST_DECLARED -Dva_list=__builtin_va_list -D_SIZE_T_DECLARED -D_WCHAR_T"
    export LDFLAGS="$LDFLAGS -L$BSDSRCDIR/lib/atf/libatf-c"
  '';
  MK_TESTS = "no";
}

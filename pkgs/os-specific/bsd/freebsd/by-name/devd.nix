{ mkDerivation, libutil, buildPackages, buildFreebsd, libatf, ... }:
mkDerivation {
  path = "sbin/devd";
  buildInputs = [libutil libatf];
  nativeBuildInputs = [
    buildPackages.bsdSetupHook buildFreebsd.freebsdSetupHook
    buildFreebsd.bmakeMinimal
    buildFreebsd.install buildFreebsd.tsort buildFreebsd.lorder buildPackages.mandoc buildPackages.groff #statHook

    buildPackages.yacc buildPackages.flex
    buildFreebsd.gencat
  ];

  preBuild = ''
    make -C $BSDSRCDIR/sbin/devd token.c
    sed -E -i -e "/include/i #include <stddef.h>" $BSDSRCDIR/sbin/devd/*.c $BSDSRCDIR/sbin/devd/*.y $BSDSRCDIR/sbin/devd/*.cc
    sed -E -i -e "s|DEVDDIR=.*|DEVDDIR=$out/etc/devd|g" $BSDSRCDIR/sbin/devd/Makefile
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -D_VA_LIST -D_VA_LIST_DECLARED -Dva_list=__builtin_va_list -D_SIZE_T_DECLARED -D_WCHAR_T"
  '';
  postInstall = ''
    for f in $(make -C $BSDSRCDIR/sbin/devd $makeFlags -V DEVD); do
      cp $BSDSRCDIR/sbin/devd/$f $out/etc/devd/$f
    done
  '';

  MK_TESTS = "no";
}

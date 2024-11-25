{ mkDerivation, lib, mandoc }:
mkDerivation {
  path = "sbin/disklabel";
  extraPaths = [ "sys/sys" "sys/ufs" ];
  patches = [ ./compat.patch ];
  extraNativeBuildInputs = [ mandoc ];
  preBuild = ''
    mkdir -p $BSDSRCDIR/sbin/disklabel/include
    ln -s $BSDSRCDIR $BSDSRCDIR/sbin/disklabel/include/bsdroot
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I$BSDSRCDIR/sbin/disklabel/include -I."
  '';
  meta.platforms = lib.platforms.all;
}

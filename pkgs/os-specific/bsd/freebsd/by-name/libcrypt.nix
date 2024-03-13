{ mkDerivation, ... }:
mkDerivation {
  path = "lib/libcrypt";

  extraPaths = [ "lib/libmd" "sys/crypto/sha2" ];

  clangFixup = true;
  MK_TESTS = "no";

  postPatch = ''
    sed -E -i -e /PRECIOUSLIB/d $BSDSRCDIR/lib/libcrypt/Makefile
  '';
}

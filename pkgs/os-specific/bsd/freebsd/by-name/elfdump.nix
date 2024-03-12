{ mkDerivation, lib, libcasper, libcapsicum }:
mkDerivation {
  path = "usr.bin/elfdump";
  buildInputs = [ libcasper libcapsicum ];

  clangFixup = true;

  meta.platforms = lib.platforms.freebsd;
}

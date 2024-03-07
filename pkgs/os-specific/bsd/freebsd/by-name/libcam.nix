{ lib, stdenv, mkDerivation, libsbuf, ... }:
mkDerivation {
  path = "lib/libcam";
  extraPaths = [ "sys/cam" ];
  buildInputs = [ libsbuf ];
  preBuild = lib.optionalString stdenv.isFreeBSD ''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -D_VA_LIST -D_VA_LIST_DECLARED -Dva_list=__builtin_va_list -D_SIZE_T -D_WCHAR_T"
  '';
  MK_TESTS = "no";
}

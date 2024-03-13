{ mkDerivation, libcrypt, libutil, ... }:
mkDerivation {
  path = "usr.sbin/pw";
  buildInputs = [libcrypt libutil];
  clangFixup = true;
  MK_TESTS = "no";
}

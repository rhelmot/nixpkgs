{ mkDerivation, lib, libjail, libncurses-tinfo, libsbuf }:
mkDerivation {
  path = "usr.bin/top";
  buildInputs = [ libjail libncurses-tinfo libsbuf ];
  preBuild = ''
    NIX_CFLAGS_COMPILE+=' -Wno-error=typedef-redefinition';
  '';

  meta.platforms = lib.platforms.freebsd;
}

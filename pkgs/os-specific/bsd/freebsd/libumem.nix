{ mkDerivation, lib }:
mkDerivation {
  path = "cddl/lib/libumem";
  extraPaths = [ "cddl/compat/opensolaris/lib/libumem" ];
  meta = with lib; {
    platforms = platforms.freebsd;
    license = with licenses; [
      cddl
      bsd2
    ];
  };
}

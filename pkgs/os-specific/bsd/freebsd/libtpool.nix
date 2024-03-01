{ mkDerivation, lib }:
mkDerivation {
  path = "cddl/lib/libtpool";
  extraPaths = [
    "cddl/compat/opensolaris/include"
    "sys/contrib/openzfs/include"
    "sys/contrib/openzfs/lib/libspl/include"
    "sys/contrib/openzfs/lib/libtpool"
    "sys/modules/zfs/zfs_config.h"
  ];
  clangFixup = true;

  meta = with lib; {
    platforms = platforms.freebsd;
    license = licenses.cddl;
  };
}

{ mkDerivation, lib }:
mkDerivation {
  path = "cddl/lib/libuutil";
  extraPaths = [
    "cddl/compat/opensolaris/include"
    "sys/contrib/openzfs/include"
    "sys/contrib/openzfs/lib/libspl/include"
    "sys/contrib/openzfs/lib/libuutil"
    "sys/modules/zfs/zfs_config.h"
  ];

  clangFixup = true;

  meta = with lib; {
    platforms = platforms.freebsd;
    license = licenses.cddl;
  };
}

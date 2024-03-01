{ mkDerivation, lib }:
mkDerivation {
  path = "cddl/lib/libzfs_core";
  extraPaths = [
    "cddl/compat/opensolaris/include"
    "sys/contrib/openzfs/include"
    "sys/contrib/openzfs/lib/libspl/include"
    "sys/contrib/openzfs/lib/libzfs_core"
    "sys/contrib/openzfs/module/os/freebsd"
    "sys/modules/zfs/zfs_config.h"
  ];

  clangFixup = true;

  # Without a prefix it will try to put object files in nonexistant directories
  preBuild = ''
    export MAKEOBJDIRPREFIX=$TMP/obj
  '';

  meta = with lib; {
    platforms = platforms.freebsd;
    license = licenses.cddl;
  };
}

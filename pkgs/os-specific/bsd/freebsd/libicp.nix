{ mkDerivation, lib }:
mkDerivation {
  path = "cddl/lib/libicp";
  extraPaths = [
    "cddl/compat/opensolaris/include"
    "sys/contrib/openzfs/include"
    "sys/contrib/openzfs/lib/libspl/include"
    "sys/contrib/openzfs/module/icp"
    "sys/contrib/openzfs/module/zfs"
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

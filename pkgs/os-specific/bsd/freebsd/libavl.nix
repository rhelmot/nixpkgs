{
  mkDerivation,
  lib,
  libspl,
}:
mkDerivation {
  path = "cddl/lib/libavl";
  extraPaths = [
    "sys/contrib/openzfs/include"
    "sys/contrib/openzfs/lib/libspl/include"
    "sys/contrib/openzfs/module/avl"
    "sys/modules/zfs/zfs_config.h"
  ];
  buildInputs = [ libspl ];

  clangFixup = true;

  meta = with lib; {
    platforms = platforms.freebsd;
    license = licenses.cddl;
  };
}

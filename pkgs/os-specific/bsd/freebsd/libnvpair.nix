{ mkDerivation, lib }:
mkDerivation {
  path = "cddl/lib/libnvpair";
  extraPaths = [
    "cddl/compat/opensolaris/include"
    "sys/contrib/openzfs/include"
    "sys/contrib/openzfs/lib/libnvpair"
    "sys/contrib/openzfs/lib/libspl/include"
    "sys/contrib/openzfs/module/nvpair"
    "sys/modules/zfs/zfs_config.h"
  ];
  clangFixup = true;

  # libnvpair uses `struct xdr_bytesrec`, which is never defined when this is set
  # no idea how this works upstream
  postPatch = ''
    sed -i 's/-DHAVE_XDR_BYTESREC//' $BSDSRCDIR/cddl/lib/libnvpair/Makefile
  '';

  # Without a prefix it will try to put object files in nonexistant directories
  preBuild = ''
    export MAKEOBJDIRPREFIX=$TMP/obj
  '';

  meta = with lib; {
    platforms = platforms.freebsd;
    license = licenses.cddl;
  };
}

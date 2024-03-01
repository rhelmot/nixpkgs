{
  mkDerivation,
  lib,
  zlib,
}:
mkDerivation {
  path = "cddl/lib/libzpool";
  extraPaths = [
    "cddl/compat/opensolaris/include"
    "sys/contrib/openzfs/include"
    "sys/contrib/openzfs/lib/libspl/include"
    "sys/contrib/openzfs/lib/libzpool"
    "sys/contrib/openzfs/module/icp/include"
    "sys/contrib/openzfs/module/lua"
    "sys/contrib/openzfs/module/os"
    "sys/contrib/openzfs/module/unicode"
    "sys/contrib/openzfs/module/zcommon"
    "sys/contrib/openzfs/module/zfs"
    "sys/contrib/openzfs/module/zstd"
    "sys/modules/zfs"
  ];
  buildInputs = [ zlib ];

  clangFixup = true;

  meta = with lib; {
    platforms = platforms.freebsd;
    license = licenses.cddl;
  };
}

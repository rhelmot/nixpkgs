{
  mkDerivation,
  lib,
  libavl,
  libbsdxml,
  libgeom,
  libnvpair,
  libspl,
  libumem,
  libuutil,
  libzfs_core,
  libzutil,
  openssl,
  zlib,
}:
mkDerivation {
  path = "cddl/lib/libzfs";
  extraPaths = [
    "cddl/compat/opensolaris/include"
    "sys/contrib/openzfs/include"
    "sys/contrib/openzfs/lib/libshare"
    "sys/contrib/openzfs/lib/libspl/include"
    "sys/contrib/openzfs/lib/libzfs"
    "sys/contrib/openzfs/module/icp"
    "sys/contrib/openzfs/module/zcommon"
    "sys/contrib/openzfs/module/zstd"
    "sys/modules/zfs"
  ];
  buildInputs = [
    libbsdxml
    libgeom
    libumem
    libspl
    libavl
    libnvpair
    libuutil
    libzutil
    libzfs_core
    openssl
    zlib
  ];

  # Without a prefix it will try to put object files in nonexistant directories
  preBuild = ''
    export MAKEOBJDIRPREFIX=$TMP/obj
  '';

  clangFixup = true;

  meta = with lib; {
    platforms = platforms.freebsd;
    license = licenses.cddl;
  };
}

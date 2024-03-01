{
  mkDerivation,
  lib,
  libavl,
  libgeom,
  libjail,
  libnvpair,
  libspl,
  libtpool,
  libuutil,
  libzfs,
  libzfs_core,
  libzutil,
  openssl,
}:
mkDerivation {
  path = "cddl/sbin/zfs";
  extraPaths = [
    "sys/contrib/openzfs"
    "sys/modules/zfs"
    "cddl/compat/opensolaris"
  ];

  buildInputs = [
    libavl
    libgeom
    libjail
    libnvpair
    libspl
    libtpool
    libuutil
    libzfs
    libzfs_core
    libzutil
    openssl
  ];

  clangFixup = true;

  meta = with lib; {
    platforms = platforms.freebsd;
    license = with licenses; [
      cddl
      bsd2
    ];
  };
}

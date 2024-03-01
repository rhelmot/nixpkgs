{
  mkDerivation,
  lib,
  libgeom,
  libjail,
  libzfs,
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
    libgeom
    libjail
    libzfs
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

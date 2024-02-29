{
  mkDerivation,
  lib,
  libbsdxml,
  libgeom,
  libjail,
  libsbuf,
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

  NIX_LDFLAGS = "-lbsdxml -lsbuf";
  buildInputs = [
    libbsdxml
    libgeom
    libjail
    libsbuf
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

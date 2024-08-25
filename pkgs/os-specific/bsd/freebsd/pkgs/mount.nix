{
  mkDerivation,
  lib,
  libutil,
  libxo,
  libkiconv,
  withMsdosfs ? true,
}:
mkDerivation {
  path = "sbin/mount";
  extraPaths = lib.optionals withMsdosfs [ "sbin/mount_msdosfs" ];
  buildInputs = [
    libutil
    libxo
  ] ++ lib.optionals withMsdosfs [ libkiconv ];

  postBuild = lib.optionalString withMsdosfs ''
    make -C $BSDSRCDIR/sbin/mount_msdosfs $makeFlags
  '';

  postInstall = lib.optionalString withMsdosfs ''
    make -C $BSDSRCDIR/sbin/mount_msdosfs $makeFlags install
  '';
}

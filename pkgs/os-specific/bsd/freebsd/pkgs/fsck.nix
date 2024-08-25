{
  lib,
  mkDerivation,
  libufs,
  compatIfNeeded,
  withUfs ? true,
  withMsdosfs ? true,
}:
mkDerivation {
  path = "sbin/fsck";
  extraPaths = [
    "sbin/mount"
  ] ++ lib.optionals withUfs [ "sbin/fsck_ffs" ] ++ lib.optionals withMsdosfs [ "sbin/fsck_msdosfs" ];

  buildInputs = compatIfNeeded ++ lib.optionals withUfs [ libufs ];

  postBuild =
    lib.optionalString withUfs ''
      make -C $BSDSRCDIR/sbin/fsck_ffs $makeFlags
    ''
    + lib.optionalString withMsdosfs ''
      make -C $BSDSRCDIR/sbin/fsck_msdosfs $makeFlags
    '';

  postInstall =
    lib.optionalString withUfs ''
      make -C $BSDSRCDIR/sbin/fsck_ffs $makeFlags install
    ''
    + lib.optionalString withMsdosfs ''
      make -C $BSDSRCDIR/sbin/fsck_msdosfs $makeFlags install
    '';

  meta.platforms = lib.platforms.freebsd;
}

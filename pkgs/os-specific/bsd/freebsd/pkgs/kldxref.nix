{
  lib,
  stdenv,
  mkDerivation,
  libelf-boot,
  compatIfNeeded,
}:
mkDerivation {
  path = "usr.sbin/kldxref";

  buildInputs = lib.optionals (!stdenv.hostPlatform.isFreeBSD) [ libelf-boot ] ++ compatIfNeeded;

  # We symlink in our modules, make it follow symlinks
  postPatch = ''
    sed -i 's/FTS_PHYSICAL/FTS_LOGICAL/' $BSDSRCDIR/usr.sbin/kldxref/kldxref.c
  '';
}

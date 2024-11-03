{
  lib,
  mkDerivation,
}:

mkDerivation {
  path = "sbin/init";
  meta.platforms = lib.platforms.openbsd;
}

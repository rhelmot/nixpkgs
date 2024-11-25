{
  stdenv,
  lib,
  mkDerivation,
  libcurses,
  compatHook,
}:

mkDerivation {
  path = "bin/ksh";
  extraPaths = ["lib/libc/gen"];
  buildInputs = [ libcurses ];
  extraNativeBuildInputs = lib.optionals (!stdenv.hostPlatform.isOpenBSD) [
    compatHook
  ];
}

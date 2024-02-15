{ lib, stdenv, mkDerivation, ... }:
mkDerivation {
  path = "sbin/init";
  extraPaths = ["sbin/mount"];
  NO_FSCHG = "yes";
  MK_TESTS = "no";

  clangFixup = true;
}

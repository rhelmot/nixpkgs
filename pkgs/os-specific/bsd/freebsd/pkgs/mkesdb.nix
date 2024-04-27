{ stdenv, mkDerivation, bsdSetupHook, freebsdSetupHook, makeMinimal, install, tsort, lorder, mandoc, groff, byacc, flex }:
mkDerivation {
  path = "usr.bin/mkesdb";

  extraPaths = [ "lib/libc/iconv" ];

  BOOTSTRAPPING = !stdenv.hostPlatform.isFreeBSD;

  nativeBuildInputs = [
    bsdSetupHook freebsdSetupHook
    makeMinimal
    install tsort lorder mandoc groff

    byacc
    flex
  ];
}

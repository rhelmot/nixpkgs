{ stdenv, mkDerivation, bsdSetupHook, mandoc, groff, byacc, flex, freebsdSetupHook, makeMinimal, install, tsort, lorder }:
mkDerivation {
  path = "usr.bin/mkcsmapper";

  extraPaths = [ "lib/libc/iconv" "lib/libiconv_modules/mapper_std" ];

  BOOTSTRAPPING = !stdenv.hostPlatform.isFreeBSD;

  nativeBuildInputs = [
    bsdSetupHook
    mandoc
    groff
    byacc
    flex

    freebsdSetupHook
    makeMinimal
    install
    tsort
    lorder
  ];
}

{ mkDerivation, ...}:
mkDerivation {
  path = "lib/libpfctl";
  extraPaths = [ "sys" ];
  preBuild = ''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-typedef-redefinition -I../../sys"
  '';
  dontFixup = true;
  # preInstall = ''
  #   set -x
  #   pwd
  #   cd lib/pfctl
  # '';
  installPhase = ''
    mkdir -p $out/lib
    ls -l *.so *.a
    cp libpfctl{,_pie}.a $out/lib
  '';
}

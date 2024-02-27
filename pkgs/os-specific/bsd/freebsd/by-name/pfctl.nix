{ mkDerivation, buildFreebsd, libnv, libpfctl, yacc, stdenv, ...}:
mkDerivation {
  path = "sbin/pfctl";
  extraPaths = [
    "sys"
    "lib/libpfctl"
  ];
  nativeBuildInputs = [
    yacc
    buildFreebsd.bmakeMinimal
    (if stdenv.hostPlatform == stdenv.buildPlatform
     then buildFreebsd.boot-install
     else buildFreebsd.install)
  ];
  buildInputs = [ libnv libpfctl ];
  MK_TESTS = "no";

  preBuild = ''
    cd sbin/pfctl
    NIX_CFLAGS_COMPILE+=' -I../../lib/libpfctl -Wno-error=typedef-redefinition';
  '';
  installFlags = [ "DESTDIR=${placeholder "out"}" ];
  postInstall = ''
    mkdir $out/sbin
    mv $out/pfctl $out/sbin/
  '';
}

{ lib, mkDerivation }:
mkDerivation {
  path = "sbin/devfs";

  outputs = [
    "out"
    "debug"
  ];

  postPatch = ''
    sed -E -i -e '/CONFSDIR|CONFSMODE/d' sbin/devfs/Makefile
  '';

  installTargets = [ "install" "installconfig" ];

  meta = {
    mainProgram = "devfs";
    platforms = lib.platforms.freebsd;
  };
}

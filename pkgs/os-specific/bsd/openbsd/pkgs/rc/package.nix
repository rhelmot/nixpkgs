{
  mkDerivation,
}:
mkDerivation {
  pname = "rc";
  path = "etc";

  patches = [ ./be-normal.patch ./use-bash.patch ];

  buildPhase = ":";

  installPhase = ''
    mkdir -p $out/etc/rc.d
    cp rc rc.d/rc.subr $out/etc
    chmod +x $out/etc/rc
  '';
}

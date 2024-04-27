{ freebsd-lib, mkDerivation, mtree, buildPackages, compatIfNeeded, lib, stdenv, libmd, libnetbsd, bsdSetupHook, freebsdSetupHook, makeMinimal, mandoc, groff, boot-install, install }:
let binstall = buildPackages.writeShellScript "binstall" (freebsd-lib.install-wrapper + ''
  @out@/bin/xinstall "''${args[@]}"
''); in mkDerivation {
  path = "usr.bin/xinstall";
  extraPaths = [ mtree.path ];
  nativeBuildInputs = [
    bsdSetupHook freebsdSetupHook
    makeMinimal mandoc groff
    (if stdenv.hostPlatform == stdenv.buildPlatform then boot-install else install)
    libmd libnetbsd
  ];
  skipIncludesPhase = true;
  buildInputs = compatIfNeeded ++ [libmd libnetbsd];
  makeFlags = [
    "STRIP=-s" # flag to install, not command
    "MK_WERROR=no"
    "TESTSDIR=${builtins.placeholder "test"}"
  ] ++ lib.optionals (stdenv.hostPlatform == stdenv.buildPlatform) [
    "BOOTSTRAPPING=1"
    "INSTALL=boot-install"
  ];
  postInstall = ''
    install -C -m 0550 ${binstall} $out/bin/binstall
    substituteInPlace $out/bin/binstall --subst-var out
    mv $out/bin/install $out/bin/xinstall
    ln -s ./binstall $out/bin/install
  '';
  outputs = [ "out" "man" "test" ];
}

{ mkDerivation, lib, hostVersion, bsdSetupHook, freebsdSetupHook, makeMinimal, install, mandoc, groff }:
mkDerivation {
  path = "usr.bin/tsort";
  extraPaths = [];
  makeFlags = [
    "STRIP=-s" # flag to install, not command
  ] ++ lib.optionals (hostVersion == "14.0") [
    "TESTSDIR=${builtins.placeholder "test"}"
  ];
  nativeBuildInputs = [
    bsdSetupHook freebsdSetupHook
    makeMinimal install mandoc groff
  ];
  outputs = [ "out" ] ++ lib.optionals (hostVersion == "14.0") [ "test" ];
}

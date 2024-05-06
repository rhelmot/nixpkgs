{ mkDerivation, lib, freebsd-lib, bsdSetupHook, freebsdSetupHook, makeMinimal, install, mandoc, groff }:
mkDerivation {
  path = "usr.bin/tsort";
  extraPaths = [];
  makeFlags = [
    "STRIP=-s" # flag to install, not command
  ] ++ lib.optionals ((lib.versions.major freebsd-lib.version) == "14") [
    "TESTSDIR=${builtins.placeholder "test"}"
  ];
  nativeBuildInputs = [
    bsdSetupHook freebsdSetupHook
    makeMinimal install mandoc groff
  ];
  outputs = [
    "out"
  ] ++ lib.optionals ((lib.versions.major freebsd-lib.version) == "14") [
    "test"
  ];
}

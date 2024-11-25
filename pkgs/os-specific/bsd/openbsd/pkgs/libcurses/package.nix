{
  mkDerivation,
  gawk,
  buildPackages,
}:

mkDerivation {
  path = "lib/libcurses";
  extraNativeBuildInputs = [
    gawk
    buildPackages.stdenv.cc
  ];
  env.AWK = "awk";
  env.HOSTCC = "${buildPackages.stdenv.cc.targetPrefix}cc";
}

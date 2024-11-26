{
  mkDerivation,
  libcMinimal,
  include,
  libgcc,
}:

mkDerivation {
  path = "lib/libmd";
  extraPaths = [
    "sys/crypto"
    "sys/sys"
  ];

  outputs = [
    "out"
    "man"
    "debug"
  ];

  noLibc = true;

  buildInputs = [
    libcMinimal
    include
    libgcc
  ];

  preBuild = ''
    mkdir $BSDSRCDIR/lib/libmd/sys
  '';
}

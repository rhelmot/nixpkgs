{
  mkDerivation,
  include,
  libcMinimal,
  libgcc,
  libkvm,
  libprocstat,
  libutil,
  libelf,
}:

mkDerivation {
  path = "lib/libdevstat";
  extraPaths = [
    "lib/libc/Versions.def"
    "sys/contrib/openzfs"
    "sys/contrib/pcg-c"
    "sys/opencrypto"
    "sys/crypto"
  ];

  outputs = [
    "out"
    "man"
    "debug"
  ];

  noLibc = true;

  buildInputs = [
    include
    libcMinimal
    libgcc
    libkvm
    libprocstat
    libutil
    libelf
  ];
}

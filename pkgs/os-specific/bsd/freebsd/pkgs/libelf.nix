{
  mkDerivation,
  m4,
  include,
  libcMinimal,
  libgcc,
}:

mkDerivation {
  path = "lib/libelf";
  extraPaths = [
    "lib/libc"
    "contrib/elftoolchain"
    "sys/sys"
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
  ];

  extraNativeBuildInputs = [
    m4
  ];
}

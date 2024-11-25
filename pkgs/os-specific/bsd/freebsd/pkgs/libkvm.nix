{
  mkDerivation,
  include,
  libcMinimal,
  libgcc,
  libelf,
}:

mkDerivation {
  path = "lib/libkvm";
  extraPaths = [
    "sys"  # wants sys/${arch}
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
    libelf
  ];

  MK_TESTS = "no";
}

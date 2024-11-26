{
  mkDerivation,
  include,
  libcMinimal,
  libgcc,
  libkvm,
}:

mkDerivation {
  path = "lib/libmemstat";

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
  ];
}

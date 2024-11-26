{
  mkDerivation,
  include,
  libelf,
  libcMinimal,
  libgcc,
}:

mkDerivation {
  path = "lib/libexecinfo";
  extraPaths = [
    "contrib/libexecinfo"
  ];

  outputs = [
    "out"
    "man"
    "debug"
  ];

  noLibc = true;

  buildInputs = [
    include
    libelf
    libcMinimal
    libgcc
  ];

  env.MK_TESTS = "no";
}

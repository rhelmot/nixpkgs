{
  mkDerivation,
  include,
  libcMinimal,
  libgcc,
}:

mkDerivation {
  path = "lib/libcrypt";
  extraPaths = [
    "sys/kern"
    "sys/crypto"
    "lib/libmd"
    "secure/lib/libcrypt"
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

  env.MK_TESTS = "no";
}

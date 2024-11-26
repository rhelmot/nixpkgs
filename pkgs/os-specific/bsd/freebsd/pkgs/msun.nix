{
  mkDerivation,
  include,
  libcMinimal,
  libgcc,
}:

mkDerivation {
  path = "lib/msun";
  extraPaths = [
    "lib/libc" # wants arch headers
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

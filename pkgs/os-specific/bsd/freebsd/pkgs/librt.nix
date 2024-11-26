{
  mkDerivation,
  include,
  libcMinimal,
  libgcc,
  libthr,
}:

mkDerivation {
  path = "lib/librt";
  extraPaths = [
    "lib/libc/include" # private headers
    "lib/libc/Versions.def"
  ];

  outputs = [
    "out"
    "debug"
  ];

  noLibc = true;

  buildInputs = [
    include
    libcMinimal
    libgcc
    libthr
  ];

  env.MK_TESTS = "no";
}

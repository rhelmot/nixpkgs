{
  mkDerivation,
  libcMinimal,
  include,
  libgcc,
}:

mkDerivation {
  path = "lib/libthr";
  extraPaths = [
    "lib/libthread_db"
    "lib/libc" # needs /include + arch-specific files
    "libexec/rtld-elf"
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

  env.MK_TESTS = "no";
}

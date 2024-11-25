{
  mkDerivation,
  include,
  libcMinimal,
  libgcc,
}:

mkDerivation {
  path = "lib/libiconv_modules";
  extraPaths = [
    "lib/libc/iconv"
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
  ];

  preBuild = ''
    export makeFlags="$makeFlags SHLIBDIR=$out/lib/i18n"
  '';
}

{
  mkDerivation,
  rpcgen,
  include,
}:

mkDerivation {
  path = "lib/librpcsvc";
  extraPaths = [
    "sys/nlm"
    "include/rpcsvc"
  ];
  noLibc = true;

  extraNativeBuildInputs = [
    rpcgen
  ];

  buildInputs = [
    include
  ];

  preBuild = ''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${include}/include/rpcsvc"
  '';

  alwaysKeepStatic = true;
}

{
  mkDerivation,
  libbsdxml,
  libsbuf,
}:
mkDerivation {
  path = "lib/libgeom";
  buildInputs = [
    libbsdxml
    libsbuf
  ];
  clangFixup = true;

  makeFlags = [
    "SHLIB_MAJOR=1"
    "STRIP=-s"
  ];
}

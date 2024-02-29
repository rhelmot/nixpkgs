{ mkDerivation, libbsdxml, libgeom, libsbuf }:
mkDerivation {
  path = "sbin/geom";
  extraPaths = [
    "lib/Makefile.inc"
    "lib/geom"
  ];

  # libgeom needs sbuf and bsdxml but linker doesn't know that
  NIX_LDFLAGS = "-lbsdxml -lsbuf";
  buildInputs = [ libbsdxml libgeom libsbuf ];

  clangFixup = true;
}

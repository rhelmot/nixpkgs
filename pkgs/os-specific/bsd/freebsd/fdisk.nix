{ mkDerivation, libbsdxml, libgeom, libsbuf }:
mkDerivation {
  path = "sbin/fdisk";

  # libgeom needs sbuf and bsdxml but linker doesn't know that
  NIX_LDFLAGS = "-lbsdxml -lsbuf";
  buildInputs = [ libbsdxml libgeom libsbuf ];
}

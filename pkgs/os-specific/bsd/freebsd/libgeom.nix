{ mkDerivation, libbsdxml }:
mkDerivation {
  path = "lib/libgeom";
  buildInputs = [ libbsdxml ];
  clangFixup = true;
}

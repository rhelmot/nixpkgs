{ mkDerivation, ... }:
mkDerivation {
  path = "lib/libnetgraph";
  clangFixup = true;
}

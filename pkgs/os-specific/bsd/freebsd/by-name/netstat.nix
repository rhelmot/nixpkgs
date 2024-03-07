{ mkDerivation, libxo, libjail, libnetgraph, ... }:
mkDerivation {
  path = "usr.bin/netstat";
  buildInputs = [ libxo libjail libnetgraph ];
  clangFixup = true;
}

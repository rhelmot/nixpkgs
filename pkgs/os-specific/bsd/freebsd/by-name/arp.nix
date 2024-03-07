{ mkDerivation, libxo, ... }:
mkDerivation {
  path = "usr.sbin/arp";
  buildInputs = [ libxo ];
  clangFixup = true;
}

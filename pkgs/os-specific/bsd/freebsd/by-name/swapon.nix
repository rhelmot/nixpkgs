{ mkDerivation }:
mkDerivation {
  path = "sbin/swapon";

  clangFixup = true;
}

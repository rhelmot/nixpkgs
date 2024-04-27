{ stdenv, lib, sourceData, versionData, buildFreebsd, patchesRoot }:

self:

lib.packagesFromDirectoryRecursive {
  callPackage = self.callPackage;
  directory = ./pkgs;
} // {

  # Keep the crawled portion of Nixpkgs finite.
  buildFreebsd = lib.dontRecurseIntoAttrs buildFreebsd;

  inherit stdenv sourceData patchesRoot versionData;
  hostVersion = versionData.revision;

  compatIsNeeded = !stdenv.hostPlatform.isFreeBSD;
  compatIfNeeded = lib.optional self.compatIsNeeded self.compat;
  freebsd-lib = import ./lib {};
  hostArchBsd = self.freebsd-lib.mkBsdArch stdenv;

  # The manual callPackages below should in principle be unnecessary, but are
  # necessary. See note in ../netbsd/default.nix

  compat = self.callPackage ./pkgs/compat/package.nix {
    inherit (buildFreebsd) makeMinimal;
  };

  csu = self.callPackage ./pkgs/csu.nix {
    inherit (buildFreebsd) makeMinimal install gencat;
  };

  include = self.callPackage ./pkgs/include/package.nix {
    inherit (buildFreebsd) rpcgen mtree;
  };

  install = self.callPackage ./pkgs/install.nix {
    inherit (buildFreebsd) makeMinimal;
    inherit (self) mtree libmd libnetbsd;
  };

  libc = self.callPackage ./pkgs/libc/package.nix {
    inherit (buildFreebsd) makeMinimal install gencat rpcgen mkcsmapper mkesdb;
  };

  libnetbsd = self.callPackage ./pkgs/libnetbsd/package.nix {
    inherit (buildFreebsd) makeMinimal boot-install install;
  };

  libmd = self.callPackage ./pkgs/libmd.nix {
    inherit (buildFreebsd) makeMinimal;
  };

  mkDerivation = self.callPackage ./pkgs/mkDerivation.nix {
    inherit (buildFreebsd) makeMinimal install tsort lorder;
  };

  mkcsmapper = self.callPackage ./pkgs/mkcsmapper.nix {
    inherit (buildFreebsd) makeMinimal install tsort lorder;
  };

  mkesdb = self.callPackage ./pkgs/mkesdb.nix {
    inherit (buildFreebsd) makeMinimal install tsort lorder;
  };

  mtree = self.callPackage ./pkgs/mtree.nix {
    inherit (self) libnetbsd libmd;
  };

  tsort = self.callPackage ./pkgs/tsort.nix {
    inherit (buildFreebsd) makeMinimal install;
  };
}

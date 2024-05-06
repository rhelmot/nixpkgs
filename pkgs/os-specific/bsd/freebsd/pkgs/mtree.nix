{ mkDerivation, patchesRoot, libnetbsd, libmd, compatIfNeeded, lib, libutil, stdenv }:
mkDerivation {
  path = "contrib/mtree";
  extraPaths = [ "contrib/mknod" ];
  buildInputs = compatIfNeeded ++ [libmd libnetbsd] ++ lib.optional (stdenv.isFreeBSD) libutil;

  patches = [ /${patchesRoot}/mtree-Makefile.patch ];

  postPatch = ''
    ln -s $BSDSRCDIR/contrib/mknod/*.c $BSDSRCDIR/contrib/mknod/*.h $BSDSRCDIR/contrib/mtree
  '';

  preBuild = ''
    export NIX_LDFLAGS="$NIX_LDFLAGS -lmd -lnetbsd ${if (!stdenv.hostPlatform.isFreeBSD) then "-legacy" else ""} ${if stdenv.isFreeBSD then "-lutil" else ""}"
  '';
}

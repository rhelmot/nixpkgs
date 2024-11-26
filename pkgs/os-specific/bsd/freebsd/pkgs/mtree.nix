{
  lib,
  stdenv,
  mkDerivation,
  compatIfNeeded,
  compatIsNeeded,
  libnetbsd,
  libmd-boot,
}:

mkDerivation {
  path = "contrib/mtree";
  extraPaths = [ "contrib/mknod" ];
  buildInputs =
    compatIfNeeded
    ++ lib.optionals (!stdenv.hostPlatform.isFreeBSD) [
      libmd-boot
    ]
    ++ [
      libnetbsd
    ];

  postPatch = ''
    ln -s $BSDSRCDIR/contrib/mknod/*.c $BSDSRCDIR/contrib/mknod/*.h $BSDSRCDIR/contrib/mtree
  '';

  preBuild = ''
    export NIX_LDFLAGS="$NIX_LDFLAGS ${
      toString (
        [
          "-lmd"
          "-lnetbsd"
        ]
        ++ lib.optional compatIsNeeded "-legacy"
        ++ lib.optional stdenv.hostPlatform.isFreeBSD "-lutil"
      )
    }"
  '';
}

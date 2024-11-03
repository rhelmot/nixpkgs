{ mkDerivation, buildPackages, lib, compatHook }:
mkDerivation {
  path = "sys/dev/microcode";
  extraPaths = [ "sys/dev" ];

  postPatch = ''
    substituteInPlace $BSDSRCDIR/sys/dev/microcode/*/Makefile --replace-quiet "/etc" "\''${FWDIR}"
  '';

  extraNativeBuildInputs = [ compatHook ];

  # build some host programs - named build.c
  preBuild = ''
    find . -name build.c -print0 | while read -r -d $'\0' f; do
      pushd "$(dirname "$f")"
      touch build.o
      ${buildPackages.stdenv.cc}/bin/cc build.c \
        -I$BSDSRCDIR/sys \
        -I${lib.getDev buildPackages.zlib}/include \
        -L${lib.getLib buildPackages.zlib}/lib \
        -lz \
        -o build
      popd
    done
  '';

  # dunno why build misses this one but install wants it
  postBuild = ''
    pushd $BSDSRCDIR/sys/dev/microcode/myx
    ./build
    popd
  '';

  preInstall = ''
    export makeFlags="$makeFlags FWDIR=$out/etc"
  '';
}

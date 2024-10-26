{
  mkDerivation,
  boot-config,
  stdenv,
  pkgsBuildTarget,
  baseConfig ? "GENERIC",
}:
assert stdenv.hostPlatform.parsed.cpu.name == "x86_64";  # TODO
mkDerivation {
  path = "sys/arch/amd64";
  pname = "sys";
  extraPaths = [ "sys" ];
  noLibc = true;

  extraNativeBuildInputs = [
    boot-config  # if we ever don't cross-compile, we need to adjust this
  ];

  # the in-kernel debugger requires compiler flags not supported by clang
  # TODO move some of these to diff files
  # TODO do we care about the sha256?
  postPatch = ''
    sed -E -i -e '/DDB/d' $BSDSRCDIR/sys/conf/GENERIC
    sed -E -i -e '/pseudo-device\tdt/d' $BSDSRCDIR/sys/arch/amd64/conf/GENERIC
    find $BSDSRCDIR -name 'Makefile*' -print0 | xargs -0 sed -E -i -e 's/-fno-ret-protector/-fno-stack-protector/g' -e 's/-nopie/-no-pie/g'
    sed -E -i -e 's_^\tinstall.*$_\tinstall bsd ''${out}/bsd_' -e s/update-link// $BSDSRCDIR/sys/arch/*/conf/Makefile.*
    sed -E -i -e 's/^PAGE_SIZE=.*$/PAGE_SIZE=4096/g' -e '/^random_uniform/a echo 0; return 0;' $BSDSRCDIR/sys/conf/makegap.sh
    sed -E -i -e 's/^v=.*$/v=0 u=nixpkgs h=nixpkgs t=`date -d @1`/g' $BSDSRCDIR/sys/conf/newvers.sh
  '';

  preConfigure = ''
    find . -print0 | xargs -0 touch -d @1
  '';

  postConfigure = ''
    export BSDOBJDIR=$TMP/obj
    mkdir $TMP/obj
    make obj
    cd conf
    config ${baseConfig}
    cd -
  '';

  preBuild = ''
    mkdir $TMP/bin
    export PATH=$TMP/bin:$PATH
    ln -s ${pkgsBuildTarget.binutils}/bin/${pkgsBuildTarget.binutils.targetPrefix}objdump $TMP/bin/objdump
    ln -s ${pkgsBuildTarget.binutils}/bin/${pkgsBuildTarget.binutils.targetPrefix}ld $TMP/bin/ld

    cd compile/${baseConfig}/obj

    # hmmmmmmm
    echo 'includes:' >>Makefile
  '';

  env.SKIPDIR = "stand";
  env.NIX_CFLAGS_COMPILE = "-Wno-unused-command-line-argument -Wno-visibility";
}

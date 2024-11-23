{
  mkDerivation,
  runtimeShell,
  m4,
}:

mkDerivation {
  pname = "MAKEDEV";
  path = "etc";

  patches = [ ./bash.patch ];

  extraNativeBuildInputs = [
    m4
  ];

  preBuild = ''
    mkdir -p $out/share/doc
  '';
  buildTargets = [ "MAKEDEV" ];

  # The install procedure is also weird since this is supposed to live in /dev
  # patches go here because there are many source (macro) programs to patch and only one generated output
  # gnu m4 doesn't seem to recognize the expr() macro but it's only used for simple arithmetic so we convert it to bash
  postInstall = ''
    mkdir -p $out/bin
    cp etc.$TARGET_MACHINE_ARCH/MAKEDEV $out/bin
    chmod +x $out/bin/MAKEDEV
    substituteInPlace $out/bin/MAKEDEV --replace-fail "/bin/sh -" "${runtimeShell}"
    sed -E -i -e '/^PATH=.*/d' -e 's/expr\((.*)\)/$((\1))/g' $out/bin/MAKEDEV
  '';

  meta.mainProgram = "MAKEDEV";
}

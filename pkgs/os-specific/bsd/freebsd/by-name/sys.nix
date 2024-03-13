{ lib, mkDerivation, buildPackages, buildFreebsd, hostArchBsd, patchesRoot
, filterSource, applyPatches
, baseConfig ? "GENERIC"
, extraFlags ? { }
}:
let
  filteredSource = filterSource {
    pname = "sys";
    path = "sys";
    extraPaths = [ "include" ];
  };
  patchedSource = applyPatches {
    src = filteredSource;
    patches = [
      /${patchesRoot}/sys-gnu-date.patch
      /${patchesRoot}/sys-no-explicit-intrinsics-dep.patch
    ];
    postPatch = ''
      for f in sys/conf/kmod.mk sys/contrib/dev/acpica/acpica_prep.sh; do
        substituteInPlace "$f" --replace 'xargs -J' 'xargs-j '
      done

      for f in sys/conf/*.mk; do
        substituteInPlace "$f" --replace 'KERN_DEBUGDIR}''${' 'KERN_DEBUGDIR_'
      done

      sed -i sys/${hostArchBsd}/conf/${baseConfig} \
        -e 's/WITH_CTF=1/WITH_CTF=0/' \
        -e '/KDTRACE/d'
    '';
  };
in mkDerivation rec {
  pname = "sys";

  # Patch source outside of this derivation so out-of-tree modules can use it
  src = patchedSource;
  COMPONENT_PATH = "sys";

  nativeBuildInputs = (with buildPackages; [
    bsdSetupHook
    mandoc
    groff
    gawk
  ]) ++ (with buildFreebsd; [
    freebsdSetupHook
    bmakeMinimal
    install
    config
    rpcgen
    file2c
    bintrans
    xargs-j
  ]);

  # --dynamic-linker /red/herring is used when building the kernel.
  NIX_ENFORCE_PURITY = 0;

  AWK = "${buildPackages.gawk}/bin/awk";

  CWARNEXTRA = "-Wno-error=shift-negative-value -Wno-address-of-packed-member";

  hardeningDisable = [
    "pic"  # generates relocations the linker can't handle
    "stackprotector"  # generates stack protection for the function generating the stack canary
  ];

  # hardeningDisable = stackprotector doesn't seem to be enough, put it in cflags too
  NIX_CFLAGS_COMPILE = "-fno-stack-protector";

  env = {
    MK_CTF = "no";
  } // (lib.flip lib.mapAttrs' extraFlags (name: value: {
    name = "MK_${lib.toUpper name}";
    value = if value then "yes" else "no";
  }));

  KODIR = "${builtins.placeholder "out"}/kernel";
  KMODDIR = "${builtins.placeholder "out"}/kernel";
  DTBDIR = "${builtins.placeholder"out"}/dbt";

  KERN_DEBUGDIR = "${builtins.placeholder "debug"}/lib/debug";
  KERN_DEBUGDIR_KODIR = "${KERN_DEBUGDIR}/kernel";
  KERN_DEBUGDIR_KMODDIR = "${KERN_DEBUGDIR}/kernel";

  skipIncludesPhase = true;

  configurePhase = ''
    runHook preConfigure

    cd ${hostArchBsd}/conf
    config ${baseConfig}

    runHook postConfigure
  '';
  preBuild = ''
    cd ../compile/${baseConfig}
  '';

  outputs = ["out" "debug"];

  meta = {
    description = "FreeBSD kernel and modules";
    platforms = lib.platforms.freebsd;
  };
}

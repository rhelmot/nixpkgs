{ system }:
((import <nixpkgs> { }).callPackage (
  {
    stdenv,
    pkgsCross,
    runCommand,
    lib,
    buildPackages,
  }:
  let
    pkgs = pkgsCross.${system};
    nar-all =
      name: pkgs:
      (runCommand name {
        requiredSystemFeatures = [ "recursive-nix" ];
      } ''
        nix_store=${lib.getBin buildPackages.nix}/bin/nix-store
        rsync=${lib.getBin buildPackages.rsync}/bin/rsync
        base=$PWD
        requisites="$($nix_store --query --requisites ${lib.concatStringsSep " " pkgs} | tac)"

        rm -f $base/nix-support/propagated-build-inputs
        for f in $requisites; do
          cd $f
          $rsync --chmod="+w" -av . $base
        done
        cd $base

        rm -rf nix nix-support
        mkdir nix-support
        for dir in $requisites; do
          cd "$dir/nix-support" 2>/dev/null || continue
          for f in $(find . -type f); do
            mkdir -p "$base/nix-support/$(dirname $f)"
            cat $f >>"$base/nix-support/$f"
          done
        done
        cd $base

        rm .nix-socket
        $nix_store --dump . >$out
      '');
  in
  nar-all "${system}-bootstrap-files.nar" (
    with pkgs;
    [
      (runCommand "bsdcp" { } "mkdir -p $out/bin; cp ${freebsd.cp}/bin/cp $out/bin/bsdcp")
      coreutils
      gnutar
      findutils
      gnumake
      gnused
      patchelf
      gnugrep
      gawk
      diffutils
      patch
      bash
      xz
      xz.dev
      gzip
      bzip2
      bzip2.dev
      curl
      expand-response-params
      binutils-unwrapped
      freebsd.libc
      llvmPackages.libcxx
      llvmPackages.libcxx.dev
      llvmPackages.compiler-rt
      llvmPackages.compiler-rt.dev
      llvmPackages.clang-unwrapped
      (freebsd.locales.override { locales = [ "C.UTF-8" ]; })
    ]
  )
) { })

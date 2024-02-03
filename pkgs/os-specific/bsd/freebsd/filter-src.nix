{ stdenv, lib, pkgsBuildBuild, runCommand, writeText, source, sourceData, hostBranch }:
{ pname, path, extraPaths ? [] }: let
  buildSystem = stdenv.buildPlatform.system;
  hostSystem = stdenv.hostPlatform.system;
  lockData = sourceData.filteredHashes.${buildSystem}.${hostSystem} or {};
  lockedHash = lockData.${pname}.hash or null;
  lockedPaths = lockData.${pname}.paths;
  sortedPaths = lib.naturalSort ([ path ] ++ extraPaths);
  extraAttrs = if lockedHash == null then
    lib.warn "${hostBranch}: ${buildSystem}.${hostSystem}.${pname} sources not locked, may cause extra rebuilds" {}
  else if lockedPaths != sortedPaths then
    lib.warn "${hostBranch}: ${buildSystem}.${hostSystem}.${pname} paths do not match locked, may cause extra rebuilds" {}
  else {
    outputHashMode = "recursive";
    outputHash = lockedHash;
  };

  filterText = writeText "${pname}-src-include"
    (lib.concatMapStringsSep "\n" (path: "/${path}") sortedPaths);

in runCommand "${pname}-filtered-src" ({
  nativeBuildInputs = [ (pkgsBuildBuild.rsync.override { enableZstd = false; enableXXHash = false; }) ];
} // extraAttrs) ''
  rsync -a -r --files-from=${filterText} ${source}/ $out
''

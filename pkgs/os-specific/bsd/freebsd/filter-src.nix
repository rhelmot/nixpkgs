{ lib, runCommand, writeText, rsync, source, sourceData }:
{ pname, path, extraPaths ? [] }: let
  lockedHash = sourceData.filteredHashes.${path}.hash or null;
  lockedPaths = sourceData.filteredHashes.${path}.paths;
  sortedPaths = lib.naturalSort ([ path ] ++ extraPaths);
  extraAttrs = if lockedHash == null then
    lib.warn "${pname} sources not locked, may cause extra rebuilds" {}
  else if lockedPaths != sortedPaths then
    lib.warn "${pname} paths do not match locked, may cause extra rebuilds" {}
  else {
    outputHashMode = "recursive";
    outputHash = lockedHash;
  };

  filterText = writeText "${pname}-src-include"
    (lib.concatMapStringsSep "\n" (path: "/${path}") sortedPaths);

in runCommand "${pname}-filtered-src" ({
  nativeBuildInputs = [ rsync ];
} // extraAttrs) ''
  rsync -a -r --files-from=${filterText} ${source}/ $out
''

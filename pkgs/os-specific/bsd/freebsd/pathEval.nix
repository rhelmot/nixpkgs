let
  options = builtins.fromJSON (builtins.getEnv "UPDATE_OPTIONS");
  lib = import "${options.nixpkgsDir}/lib";

  filterSplice = lib.flip builtins.removeAttrs [
    "override"
    "overrideDerivation"
    "recurseForDerivations"
  ];

  handlePackage = pkg:
    let
      attempt = lib.nameValuePair pkg.pname {
        # naturalSort isn't necessary, we just need a sort we can easily reuse for comparison
        paths = lib.naturalSort ([ pkg.path ] ++ pkg.extraPaths or [ ]);
      };
      seq = builtins.deepSeq attempt attempt;
      tried = builtins.tryEval seq;
      triedHasPath = builtins.tryEval (pkg ? path);
      hasPath = triedHasPath.success && triedHasPath.value;
    in lib.optional (hasPath && tried.success) tried.value;

  handleBranch = name: scope:
    let results = lib.concatMap handlePackage (lib.attrValues scope);
    in lib.listToAttrs results;

  handleSystem = buildSystem: hostSystem:
    let
      pkgs = import "${options.nixpkgsDir}" { inherit buildSystem hostSystem; };
    in lib.mapAttrs handleBranch (filterSplice pkgs.freebsd.branches);

  handleBuildSystem = build:
    lib.listToAttrs
    (map (host: lib.nameValuePair host (handleSystem build host))
      options.systems);

in lib.listToAttrs
(map (build: lib.nameValuePair build (handleBuildSystem build)) options.systems)

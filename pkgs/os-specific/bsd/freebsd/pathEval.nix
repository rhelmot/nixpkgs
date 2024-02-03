let
  options = builtins.fromJSON (builtins.getEnv "UPDATE_OPTIONS");
  lib = import "${options.nixpkgsDir}/lib";

  handlePackage = pkg:
    let
      attempt = lib.nameValuePair pkg.path {
        pname = pkg.pname;
        # naturalSort isn't necessary, we just need a sort we can easily reuse for comparison
        paths = lib.naturalSort ([ pkg.path ] ++ pkg.extraPaths or [ ]);
      };
      seq = builtins.deepSeq attempt attempt;
      tried = builtins.tryEval seq;
    in lib.optional (pkg ? path && tried.success) tried.value;

  handleBranch = name: scope:
    let results = lib.concatMap handlePackage (lib.attrValues scope);
    in lib.listToAttrs results;

  handleSystem = system:
    let pkgs = import "${options.nixpkgsDir}" { inherit system; };
    in lib.mapAttrs handleBranch pkgs.freebsd.branches;
in lib.listToAttrs
(map (p: lib.nameValuePair p (handleSystem p)) options.systems)


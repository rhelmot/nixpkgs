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
      pkgs = import "${options.nixpkgsDir}" {
        localSystem = buildSystem;
        crossSystem = hostSystem;
      };
    in lib.mapAttrs handleBranch (filterSplice pkgs.freebsd.branches);

  handleBuildSystem = build:
    let
      # Include the build system as a host for things like bmake
      # cross compiling pkgs.freebsd for linux from freebsd doesn't work though
      isFreebsd = lib.any (e: e == build) options.freebsdSystems;
      hostSystems = options.freebsdSystems ++ lib.optional (!isFreebsd) build;
    in lib.listToAttrs
    (map (host: lib.nameValuePair host (handleSystem build host)) hostSystems);

in lib.listToAttrs
(map (build: lib.nameValuePair build (handleBuildSystem build))
  options.buildSystems)

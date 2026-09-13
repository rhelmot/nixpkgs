# TODO: Get rid of kube-addon-manager in the future for the following reasons
# - it is basically just a shell script wrapped around kubectl
# - it assumes that it is clusterAdmin or can gain clusterAdmin rights through serviceAccount
# - it is designed to be used with k8s system components only
# - it would be better with a more Nix-oriented way of managing addons
{
  config,
  lib,
  pkgs,
  ...
}:
let
  top = config.services.kubernetes;
  cfg = top.addonManager;

  isRBACEnabled = lib.elem "RBAC" top.apiserver.authorizationMode;

  addons = pkgs.runCommand "kubernetes-addons" { } ''
    mkdir -p $out
    # since we are mounting the addons to the addon manager, they need to be copied
    ${lib.concatMapStringsSep ";" (a: "cp -v ${a}/* $out/") (
      lib.mapAttrsToList (name: addon: pkgs.writeTextDir "${name}.json" (builtins.toJSON addon)) (
        cfg.addons
      )
    )}
  '';
in
{
  ###### interface
  options.services.kubernetes.addonManager = with lib.types; {

    bootstrapAddons = lib.mkOption {
      description = ''
        Bootstrap addons are like regular addons, but they are applied with cluster-admin rights.
        They are applied at addon-manager startup only.
      '';
      default = { };
      type = attrsOf attrs;
      example = lib.literalExpression ''
        {
          "my-service" = {
            "apiVersion" = "v1";
            "kind" = "Service";
            "metadata" = {
              "name" = "my-service";
              "namespace" = "default";
            };
            "spec" = { ... };
          };
        }
      '';
    };

    addons = lib.mkOption {
      description = "Kubernetes addons (any kind of Kubernetes resource can be an addon).";
      default = { };
      type = attrsOf (either attrs (listOf attrs));
      example = lib.literalExpression ''
        {
          "my-service" = {
            "apiVersion" = "v1";
            "kind" = "Service";
            "metadata" = {
              "name" = "my-service";
              "namespace" = "default";
            };
            "spec" = { ... };
          };
        }
        // import <nixpkgs/nixos/modules/services/cluster/kubernetes/dns.nix> { cfg = config.services.kubernetes; };
      '';
    };

    kubeconfig = top.lib.mkKubeConfigOptions "addon-manager" "Add-on manager";
    bootstrapKubeconfig = top.lib.mkKubeConfigOptions "bootstrap-addon-manager" "Bootstrap add-on manager";

    enable = lib.mkEnableOption "Kubernetes addon manager";
  };

  ###### implementation
  config = lib.mkIf cfg.enable {
    environment.etc."kubernetes/addons".source = "${addons}/";

    systemd.services.kube-addon-manager = lib.mkMerge [{
      description = "Kubernetes addon manager";
      wantedBy = [ "kubernetes.target" ];
      after = [ "kube-apiserver.service" ];
      environment.ADDON_PATH = "/etc/kubernetes/addons/";
      environment.KUBECONFIG = cfg.kubeconfig.path;
      path = [ pkgs.gawk ];
      serviceConfig = {
        Slice = "kubernetes.slice";
        ExecStart = "${top.package}/bin/kube-addons";
        WorkingDirectory = top.dataDir;
        User = "kubernetes";
        Group = "kubernetes";
        Restart = "on-failure";
        RestartSec = 10;
      };
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
    } (lib.mkIf (cfg.bootstrapAddons != {}) {
      serviceConfig.PermissionsStartOnly = true;
      preStart =
        let
          files = lib.mapAttrsToList (
            n: v: pkgs.writeText "${n}.json" (builtins.toJSON v)
          ) cfg.bootstrapAddons;
        in
        ''
          export KUBECONFIG=${cfg.bootstrapKubeconfig.path}
          ${top.package}/bin/kubectl apply -f ${lib.concatStringsSep " \\\n -f " files}
        '';
    })];

    services.kubernetes.addonManager.bootstrapAddons = lib.mkIf isRBACEnabled (
      let
        name = "system:kube-addon-manager";
        namespace = "kube-system";
      in
      {

        kube-addon-manager-r = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "Role";
          metadata = {
            inherit name namespace;
          };
          rules = [
            {
              apiGroups = [ "*" ];
              resources = [ "*" ];
              verbs = [ "*" ];
            }
          ];
        };

        kube-addon-manager-rb = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "RoleBinding";
          metadata = {
            inherit name namespace;
          };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "Role";
            inherit name;
          };
          subjects = [
            {
              apiGroup = "rbac.authorization.k8s.io";
              kind = "User";
              inherit name;
            }
          ];
        };

        kube-addon-manager-cluster-lister-cr = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRole";
          metadata = {
            name = "${name}:cluster-lister";
          };
          rules = [
            {
              apiGroups = [ "*" ];
              resources = [ "*" ];
              verbs = [ "list" ];
            }
          ];
        };

        kube-addon-manager-cluster-lister-crb = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRoleBinding";
          metadata = {
            name = "${name}:cluster-lister";
          };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            name = "${name}:cluster-lister";
          };
          subjects = [
            {
              kind = "User";
              inherit name;
            }
          ];
        };
      }
    );

    services.kubernetes.pki.certs = {
      addonManager = top.lib.mkCert {
        name = "kube-addon-manager";
        CN = "system:kube-addon-manager";
        action = "systemctl restart kube-addon-manager.service";
      };
    };
  };

  meta.buildDocsInSandbox = false;
}

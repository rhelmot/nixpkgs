{ lib, config, pkgs, ... }:
let
  top = config.services.kubernetes;
  cfg = top.kubeadmCerts;
  configDir' = "kubernetes/kubeconfig";
  configDir = "/etc/${configDir'}";
  pkiDir' = "kubernetes/pki";
  pkiDir = "/etc/${pkiDir'}";
  isMaster = lib.elem "master" top.roles;

  initConfig = {
    apiVersion = "kubeadm.k8s.io/v1beta4";
    kind = "InitConfiguration";
  };
  clusterConfig = {
    apiVersion = "kubeadm.k8s.io/v1beta4";
    kind = "ClusterConfiguration";
    controlPlaneEndpoint = lib.strings.removePrefix "https://" top.apiserverAddress;
    certificatesDir = pkiDir;
  };
  joinConfig = {
    apiVersion = "kubeadm.k8s.io/v1beta4";
    kind = "JoinConfiguration";
    discovery = {
      bootstrapToken = {
        apiServerEndpoint = lib.strings.removePrefix "https://" top.apiserverAddress;
        token = "";
        caCertHashes = [];
      };
      tlsBootstrapToken = "";
    };
  };
  # some of these options cannot be specified on the command line but you can't mix/match command line and config file...
  kubeadmConfig = builtins.toFile "cluster.yaml" "${builtins.toJSON initConfig}\n---\n${builtins.toJSON clusterConfig}\n---\n${builtins.toJSON joinConfig}\n";

  kubeadmAdminRolebinding = builtins.toFile "kubeadm-admin-rolebinding.yaml" (builtins.toJSON {
    kind = "ClusterRoleBinding";
    apiVersion = "rbac.authorization.k8s.io/v1";
    metadata = {
      name = "kubeadm:cluster-admins";
    };
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io";
      kind = "ClusterRole";
      name = "cluster-admin";
    };
    subjects = [{
      kind = "Group";
      name = "kubeadm:cluster-admins";
    }];
  });

  # for the below scripts, we need root because kubeadm wants to run systemctl commands
  # but also we need it to write files with the kubernetes user ownership since we run
  # e.g. kubelet as non-root. and furthermore it will be doing both of these things within
  # a single operation (at least during the join kubelet phase) so trying to fix it from
  # above would be a race. so... bind mount with uid mapping
  controlPlaneEndpoint = lib.strings.removePrefix "https://" top.apiserverAddress;
  initScript = pkgs.writeShellScriptBin "nixos-kubernetes-node-init" ''
    if [[ -n "$1" ]]; then
      cat <<EOF
    Usage: $0

    This script will:
      - Bootstrap some certificates
      - Generate kubeconfig files for control plane components
      - Restart kubelet
      - Print out a command to use to join other nodes to this cluster
    EOF
      exit 1
    fi
    if [[ "$(id -u)" != 0 ]]; then
      echo "Need root"
      exit 1
    fi

    set -e
    TMPROOT="/var/lib/kubernetes/nixos-kubeadm-tmp"
    mkdir -p "$TMPROOT/kubeconfig" "$TMPROOT/pki"
    mount --map-users "$(id -u etcd):1:1" --map-users "$(id -u kubernetes):0:1" --map-groups 0:0:65535 --bind "${pkiDir}" "$TMPROOT/pki"
    mount --map-users "$(id -u kubernetes):0:1" --map-groups 0:0:65535 --bind "${configDir}" "$TMPROOT/kubeconfig"
    cleanup () {
      umount "$TMPROOT/kubeconfig"
      umount "$TMPROOT/pki"
      rmdir "$TMPROOT/kubeconfig"
      rmdir "$TMPROOT/pki"
      rm -f "$TMPROOT/kubeadm.yaml"
      rmdir "$TMPROOT"
    }
    trap 'set +x; cleanup' EXIT

    yq -y --arg certDir "$TMPROOT/pki" '
      if .kind == "ClusterConfiguration" then .certificatesDir = $certDir else . end |
    .' "${kubeadmConfig}" >"$TMPROOT/kubeadm.yaml"

    set -x
    kubeadm init phase certs all --config "$TMPROOT/kubeadm.yaml"
    kubeadm init phase kubeconfig all --config "$TMPROOT/kubeadm.yaml" --kubeconfig-dir "$TMPROOT/kubeconfig"
    chown -R etcd:etcd "${pkiDir}/etcd/"
    chown root:root "${configDir}/super-admin.conf"

    systemctl restart kubelet kube-apiserver kube-controller-manager kube-scheduler etcd
    # make admin.conf work - kubeadm won't do this since we provide --kubeconfig
    kubectl --kubeconfig "${configDir}/super-admin.conf" apply -f "${kubeadmAdminRolebinding}"
    ${
      # it's not super clear what the actual requirements are for the proxy to authenticate.
      # as far as I can tell, any kubeconfig that authorizes the user system:kube-proxy will do.
      # this looks weird because kubeadm wants kube-proxy to be a managed component.
      lib.optionalString top.proxy.enable ''
      (umask u=rwx,g=,o= && kubeadm kubeconfig user --config "${kubeadmConfig}" --client-name system:kube-proxy >"$TMPROOT/kubeconfig/kube-proxy.conf")
      yq --arg server "https://${top.apiserver.advertiseAddress}:${toString top.apiserver.securePort}" -i -y '.clusters.[0].cluster.server = $server' "$TMPROOT/kubeconfig/kube-proxy.conf"
      systemctl restart kube-proxy
    ''}

    # exec does not trigger EXIT traps
    set +x
    cleanup
    exec nixos-kubernetes-node-invite
  '';

  inviteScript = pkgs.writeShellScriptBin "nixos-kubernetes-node-invite" ''
    set -e

    TMPROOT="/var/lib/kubernetes/nixos-kubeadm-tmp"
    # upsettingly, even though we have no mutation to do to this directory, we have to set up the bind mount anyway
    # because the config gets uploaded to the cluster and downloaded for the join phase (cannot be preempted or overridden)
    mkdir -p "$TMPROOT/pki"
    mount --map-users "$(id -u etcd):1:1" --map-users "$(id -u kubernetes):0:1" --map-groups 0:0:65535 --bind "${pkiDir}" "$TMPROOT/pki"
    cp "${kubeadmConfig}" "$TMPROOT/kubeadm.yaml"

    cleanup () {
      rm "$TMPROOT/kubeadm.yaml"
      umount "$TMPROOT/pki"
      rmdir "$TMPROOT/pki"
      rmdir "$TMPROOT"
    }
    trap 'set +x; cleanup' EXIT
    set -x

    # annoyingly, this version of the command does not print out the token conveniently
    # but the version which does does not upload the appropriate manifests...
    # TODO can we upload the manifests separately, perhaps in the previous stage?
    TOKEN="$(kubeadm init phase bootstrap-token --kubeconfig "${configDir}/admin.conf" | grep -o 'Using token: .*' | cut -d' ' -f3)"
    CERTKEY="$(kubeadm certs certificate-key)"
    CAHASH="$(openssl x509 -in "${pkiDir}/ca.crt" -pubkey -noout | openssl asn1parse -noout -out - | sha256sum | cut -d' ' -f1)"

    yq -y -i --arg certKey "$CERTKEY" --arg certDir "$TMPROOT/pki" '
      if .kind == "ClusterConfiguration" then .certificatesDir = $certDir else . end |
      if .kind == "InitConfiguration" then .certificateKey = $certKey else . end |
    .' "$TMPROOT/kubeadm.yaml"

    kubeadm init phase upload-config all --kubeconfig "${configDir}/admin.conf" --config "$TMPROOT/kubeadm.yaml"
    kubeadm init phase upload-certs --kubeconfig "${configDir}/admin.conf" --upload-certs --skip-certificate-key-print --config "$TMPROOT/kubeadm.yaml"

    set +x
    cat <<EOF

    Join more nodes to the cluster with the following:

      nixos-kubernetes-node-join "$TOKEN" "$CERTKEY" "$CAHASH"

    EOF
  '';

  joinScript = pkgs.writeShellScriptBin "nixos-kubernetes-node-join" ''
    if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
      cat <<EOF
    Usage: as specified by nixos-kubernetes-node-init from the bootstrap node

    This script will (as relevant to this node):
      - Download some certificates
      - Generate some local certificates
      - Generate kubeconfig files for control plane components
      - Start kubelet
    EOF
      exit 1
    fi
    if [[ "$(id -u)" != 0 ]]; then
      echo "Need root"
      exit 1
    fi

    TOKEN="$1"
    CERTKEY="$2"
    CAHASH="$3"

    TMPROOT="/var/lib/kubernetes/nixos-kubeadm-tmp"
    mkdir -p "$TMPROOT/kubeconfig" "$TMPROOT/pki"
    mount --map-users "$(id -u etcd):1:1" --map-users "$(id -u kubernetes):0:1" --map-groups 0:0:65535 --bind "${pkiDir}" "$TMPROOT/pki"
    mount --map-users "$(id -u kubernetes):0:1" --map-groups 0:0:65535 --bind "${configDir}" "$TMPROOT/kubeconfig"
    trap 'set +x; umount "$TMPROOT/kubeconfig"; umount "$TMPROOT/pki"; rmdir "$TMPROOT/kubeconfig"; rmdir "$TMPROOT/pki"; rm -f "$TMPROOT/kubeadm.yaml"; rmdir "$TMPROOT"' EXIT

    yq -y --arg certHash "sha256:$CAHASH" --arg certKey "$CERTKEY" --arg token "$TOKEN" --arg certDir "$TMPROOT/pki" '
      if .kind == "ClusterConfiguration" then .certificatesDir = $certDir else . end |
      if .kind == "JoinConfiguration" then .discovery.bootstrapToken.caCertHashes = [ $certHash ] else . end |
      if .kind == "JoinConfiguration" then .discovery.bootstrapToken.token = $token else . end |
      if .kind == "JoinConfiguration" then .discovery.tlsBootstrapToken = $token else . end |
      ${
        lib.optionalString isMaster ''
          if .kind == "JoinConfiguration" then .controlPlane = { certificateKey: $certKey } else . end |
        ''
      }
    .' "${kubeadmConfig}" >"$TMPROOT/kubeadm.yaml"

    FLAGS=(--config "$TMPROOT/kubeadm.yaml")
    set -ex
    # control plane stuff will simply be a nop without the controlPlane config
    kubeadm join phase control-plane-prepare download-certs "''${FLAGS[@]}"
    kubeadm join phase control-plane-prepare certs "''${FLAGS[@]}"
    kubeadm join phase control-plane-prepare kubeconfig "''${FLAGS[@]}" --kubeconfig-dir "$TMPROOT/kubeconfig"
    chown -R etcd:etcd "${pkiDir}/etcd/"

    PEER="$(KUBECONFIG=${configDir}/admin.conf kubectl get nodes -o yaml | yq -r '.items.[0].status.addresses.[] | select(.type == "InternalIP") | .address')"
    etcdctl --cacert ${pkiDir}/etcd/ca.crt --cert ${pkiDir}/etcd/peer.crt --key ${pkiDir}/etcd/peer.key --endpoints "$PEER:2379" member add ${config.services.etcd.name} --peer-urls "${lib.concatStringsSep "," config.services.etcd.initialAdvertisePeerUrls}"
    systemctl restart etcd

    systemctl restart kube-apiserver kube-controller-manager kube-scheduler
    kubeadm join phase kubelet-start "''${FLAGS[@]}" --kubeconfig-dir "$TMPROOT/kubeconfig"
    kubeadm join phase kubelet-wait-bootstrap "''${FLAGS[@]}" --kubeconfig "${configDir}/admin.conf" --kubeconfig-dir "${configDir}"
    ${
      # see above
      lib.optionalString top.proxy.enable ''
      (umask u=rwx,g=,o= && kubeadm kubeconfig user --config "$TMPROOT/kubeadm.yaml" --client-name system:kube-proxy >"$TMPROOT/kubeconfig/kube-proxy.conf")
      ${
        # non-masters won't have an apiserver. shove them at the master/loadbalancer
        lib.optionalString isMaster
        ''yq --arg server "https://${top.apiserver.advertiseAddress}:${toString top.apiserver.securePort}" -i -y '.clusters.[0].cluster.server = $server' "$TMPROOT/kubeconfig/kube-proxy.conf"''
      }
      systemctl restart kube-proxy
    ''}

    set +x
    cat <<EOF

    You did it!
      (go you!)

    EOF
  '';
in {
  options.services.kubernetes.kubeadmCerts = {
    enable = lib.mkEnableOption "managing certs via kubeadm";

    isBootstrap = lib.mkOption {
      description = "Set this to enable to bootstrapping script. You should not set this on more than one machine.";
      type = lib.types.bool;
      default = false;
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.kubernetes.easyCerts;
        message = "services.kubernetes.easyCerts conflicts with services.kubernetes.kubeadmCerts";
      }
    ];

    services.kubernetes = {
      caFile = "${pkiDir}/ca.crt";
      apiserver.etcd.caFile = "${pkiDir}/etcd/ca.crt";
      apiserver.etcd.certFile = "${pkiDir}/apiserver-etcd-client.crt";
      apiserver.etcd.keyFile = "${pkiDir}/apiserver-etcd-client.key";
      apiserver.kubeletClientCertFile = "${pkiDir}/apiserver-kubelet-client.crt";
      apiserver.kubeletClientKeyFile = "${pkiDir}/apiserver-kubelet-client.key";
      apiserver.proxyClientCertFile = "${pkiDir}/front-proxy-client.crt";
      apiserver.proxyClientKeyFile = "${pkiDir}/front-proxy-client.key";
      apiserver.serviceAccountKeyFile = "${pkiDir}/sa.pub";
      apiserver.serviceAccountSigningKeyFile = "${pkiDir}/sa.key";
      apiserver.tlsCertFile = "${pkiDir}/apiserver.crt";
      apiserver.tlsKeyFile = "${pkiDir}/apiserver.key";
      apiserver.extraOpts = "--enable-bootstrap-token-auth";

      controllerManager.kubeconfig.path = "${configDir}/controller-manager.conf";
      controllerManager.extraOpts = "--controllers=*,bootstrapsigner,tokencleaner --cluster-signing-cert-file=${pkiDir}/ca.crt --cluster-signing-key-file=${pkiDir}/ca.key";
      scheduler.kubeconfig.path = "${configDir}/scheduler.conf";
      # note: kube-proxy is considered an addon by kubeadm, same as coredns...
      # TODO what goes here
      # proxy.kubeconfig.path = "${configDir}/admin.conf";
      # populated by kubeadm, ignored if the normal config exists
      kubelet.extraOpts = "--bootstrap-kubeconfig ${configDir}/bootstrap-kubelet.conf";
      kubelet.kubeconfig.path = "${configDir}/kubelet.conf";
    };
    services.etcd.certFile = "${pkiDir}/etcd/server.crt";
    services.etcd.clientCertAuth = true;
    services.etcd.keyFile = "${pkiDir}/etcd/server.key";
    services.etcd.peerCertFile = "${pkiDir}/etcd/peer.crt";
    services.etcd.peerClientCertAuth = true;
    services.etcd.peerKeyFile = "${pkiDir}/etcd/peer.key";
    services.etcd.trustedCaFile = "${pkiDir}/etcd/ca.crt";
    services.etcd.openFirewall = true;
    services.etcd.initialClusterState = if cfg.isBootstrap then "new" else "existing";

    environment.etc.${pkiDir'}.source = "/var/lib/kubernetes/pki";
    environment.etc.${configDir'}.source = "/var/lib/kubernetes/kubeconfig";

    systemd.tmpfiles.settings."kubeadmCerts" = {
      "/var/lib/kubernetes/pki".d = {
        user = "kubernetes";
        group = "etcd";
        mode = "0750";
      };
      "/var/lib/kubernetes/kubeconfig".d = {
        user = "kubernetes";
        group = "kubernetes";
        mode = "0700";
      };
    };

    environment.systemPackages = lib.mkMerge [
      [ joinScript top.package pkgs.yq pkgs.openssl ]
      (lib.mkIf cfg.isBootstrap [ initScript inviteScript ])
    ];
  };
}

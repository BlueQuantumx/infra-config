{
  config,
  lib,
  inputs,
  defaults,
  ...
}:
{
  imports = [
    ./disko.nix
    ./sops.nix
    ./substore.nix
    inputs.self.nixosModules.base
    inputs.self.nixosModules.server
    inputs.self.nixosModules.cloud-vm
    inputs.self.nixosModules.overlays
    inputs.self.nixosModules.sops
    inputs.self.nixosModules.prelude-linux
    inputs.self.nixosModules.substore
    inputs.self.nixosModules.azure
    inputs.self.nixosModules.my-et-network
  ];

  # EasyTier mesh, kept as an optional fallback. Disabled by default through
  # defaults.easytier.enable; when off, neither the service nor its sops secret
  # is activated. Tailscale (below) is the active mesh.
  my-et-network = {
    enable = defaults.easytier.enable;
    public = true;
    ipv4 = defaults.easytier.meshIpv4;
    isExitNode = true;
    wireguardPortal = "wg://0.0.0.0:${toString defaults.easytier.portalPort}/10.14.14.0/24";
    secretFile =
      if defaults.easytier.enable then config.sops.secrets."my-et-network/secret".path else null;
  };

  sops.secrets."my-et-network/secret" = lib.mkIf defaults.easytier.enable {
    sopsFile = ../../secrets/mesh.yaml;
  };

  # Tailscale enrollment keys, minted by the tailnet OpenTofu stack and
  # synced into sops. azure also carries the client keys, injected into the
  # sub-store templates for the Mac, iOS, and Linux desktop sing-box endpoints.
  sops.secrets = {
    "tailscale/authkey_azure" = {
      sopsFile = ../../secrets/azure.yaml;
    };
    "tailscale/authkey_mac" = {
      sopsFile = ../../secrets/azure.yaml;
    };
    "tailscale/authkey_ios" = {
      sopsFile = ../../secrets/azure.yaml;
    };
    "tailscale/authkey_linux_desktop" = {
      sopsFile = ../../secrets/azure.yaml;
    };
  };

  # Tailscale: exit + server node. The sops-supplied auth key is tagged
  # tag:server and tag:exit, so the node is classified at enrollment and its
  # advertised exit node is auto-approved by the tailnet ACL.
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale/authkey_azure".path;
    useRoutingFeatures = "server";
    extraUpFlags = [ "--advertise-exit-node" ];
  };

  # Tailscale and EasyTier both claim net.*.conf.all.forwarding at the same
  # module priority (mkOverride 97). When the optional EasyTier fallback is
  # enabled alongside Tailscale, break the tie here.
  boot.kernel.sysctl = lib.mkIf defaults.easytier.enable {
    "net.ipv4.conf.all.forwarding" = lib.mkForce true;
    "net.ipv6.conf.all.forwarding" = lib.mkForce true;
  };

  # Azure VMs are Hyper-V guests; this pulls in the hv_* drivers for the
  # boot disk and NIC plus the hyperv-daemons
  virtualisation.hypervGuest.enable = true;

  # Integrate home-manager as a NixOS module
  home-manager.users.luyan.imports = [ ../../home-manager/luyan-azure.nix ];

  services.caddy = {
    enable = true;
    virtualHosts."${defaults.subdomains.navidrome}.${defaults.domain}" = {
      extraConfig = ''
        reverse_proxy ${defaults.hosts.raspi.hostname}.${defaults.tailnet.magicDnsDomain}:4533
      '';
    };
  };
}

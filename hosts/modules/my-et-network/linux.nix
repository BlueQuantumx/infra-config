{
  config,
  lib,
  ...
}:
{
  # NixOS entry point: NixOS hosts import ../../modules/my-et-network.nix,
  # which forwards here. Re-uses the shared option declarations.
  imports = [
    ./options.nix
  ];

  config = lib.mkIf config.my-et-network.enable (
    let
      cfg = config.my-et-network;

      # WireGuard client portal binds its own UDP port, e.g. 11013 in
      # "wg://0.0.0.0:11013/10.14.14.0/24".
      portalPort = lib.toInt (
        builtins.head (builtins.match "wg://[^:/]*:([0-9]+)/.*" cfg.wireguardPortal)
      );

      listeners = lib.optionals cfg.public (
        [
          "tcp://0.0.0.0:${toString cfg.listenPort}"
          "udp://0.0.0.0:${toString cfg.listenPort}"
        ]
        ++ lib.optionals cfg.wireguard [ "wg://0.0.0.0:${toString cfg.wireguardListenPort}" ]
      );

      exitArgs =
        (lib.optional cfg.isExitNode "--enable-exit-node")
        ++ lib.concatMap (ip: [
          "--exit-nodes"
          ip
        ]) cfg.exitNodes
        ++ lib.concatMap (net: [
          "-n"
          net
        ]) cfg.proxyNetworks;

      portalArgs = lib.optionals (cfg.wireguardPortal != null) [
        "--vpn-portal"
        cfg.wireguardPortal
      ];
    in
    {
      services.easytier = {
        enable = true;
        # sysctl net.ipv4/6.conf.all.forwarding, needed for exit nodes and
        # subnet proxy forwarding
        allowSystemForward = cfg.isExitNode;
        instances."${cfg.networkName}" = {
          settings = {
            network_name = cfg.networkName;
            hostname = if cfg.hostname != null then cfg.hostname else config.networking.hostName;
            ipv4 = cfg.ipv4;
            # pass through: when unset, leave easytier defaults (no TUN unless
            # ipv4 or dhcp is given)
            dhcp = lib.mkIf (cfg.dhcp != null) cfg.dhcp;
            listeners = listeners;
            peers = cfg.peers;
          };
          # stable TUN name so exit-node firewall/NAT rules can reference it
          extraSettings = {
            flags.dev_name = cfg.devName;
          };
          environmentFiles = lib.optional (cfg.secretFile != null) cfg.secretFile;
          extraArgs = exitArgs ++ portalArgs ++ cfg.extraArgs;
        };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.public [ cfg.listenPort ];
      networking.firewall.allowedUDPPorts = lib.mkIf cfg.public (
        [ cfg.listenPort ]
        ++ lib.optionals cfg.wireguard [ cfg.wireguardListenPort ]
        ++ lib.optionals (cfg.wireguardPortal != null) [ portalPort ]
      );

      # Exit node: masquerade mesh traffic out through the physical interface
      # and allow forwarding to/from the TUN device.
      networking.nat.enable = lib.mkIf cfg.isExitNode true;
      networking.nat.internalInterfaces = lib.mkIf cfg.isExitNode [ cfg.devName ];
      networking.firewall.extraForwardRules = lib.mkIf cfg.isExitNode ''
        iptables -A FORWARD -i ${cfg.devName} -j ACCEPT
        iptables -A FORWARD -o ${cfg.devName} -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
      '';

      assertions = [
        {
          assertion = cfg.dhcp != true || cfg.ipv4 == null;
          message = "my-et-network: dhcp = true and ipv4 are mutually exclusive; set only one of them.";
        }
        {
          assertion = cfg.wireguardPortal == null || cfg.public;
          message = "my-et-network: wireguardPortal requires public = true (portal must be reachable by clients).";
        }
      ];
    }
  );
}

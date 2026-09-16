{ lib, ... }:
{
  options.my-et-network = {
    enable = lib.mkEnableOption "EasyTier mesh network (my-et-network)";

    networkName = lib.mkOption {
      type = lib.types.str;
      default = "my-et-network";
      description = "EasyTier virtual network name, must be identical on all nodes.";
    };

    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hostname advertised in the mesh; defaults to the system hostname.";
    };

    ipv4 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.144.144.1/24";
      description = ''
        Fixed virtual IPv4 (CIDR) of this node. Passed through as-is; when
        unset easytier decides (no TUN device unless dhcp is enabled).
      '';
    };

    dhcp = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Use EasyTier DHCP. Passed through as-is; when unset easytier's
        default applies (dhcp disabled). Mutually exclusive with ipv4.
      '';
    };

    peers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Initial peer URIs (tcp/udp/wg/ws/wss/quic/faketcp...).";
    };

    public = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Host has a public IP reachable from the internet: enables listeners and opens firewall ports.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 61070;
      description = "TCP/UDP listener port (only used when public = true).";
    };

    wireguard = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the WireGuard transport: adds a wg:// listener on public hosts, and wg:// peers become usable.";
    };

    wireguardListenPort = lib.mkOption {
      type = lib.types.port;
      default = 61071;
      description = "WireGuard listener port (only used when public = true).";
    };

    wireguardPortal = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "wg://0.0.0.0:11013/10.14.14.0/24";
      description = ''
        WireGuard client access portal (--vpn-portal): lets plain WireGuard
        clients join the mesh. Only meaningful on public hosts.
      '';
    };

    isExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Advertise this node as gateway/exit (--enable-exit-node): all traffic
        from mesh peers can be routed out through this host. Enables IP
        forwarding and NAT. Linux only.
      '';
    };

    exitNodes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "10.144.144.1" ];
      description = "Virtual IPv4s of exit nodes to use for outbound internet traffic (--exit-nodes).";
    };

    proxyNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "192.168.1.0/24" ];
      description = "Local subnets to advertise into the mesh (-n subnet proxy).";
    };

    devName = lib.mkOption {
      type = lib.types.str;
      default = "et0";
      description = "TUN interface name, referenced by exit-node firewall/NAT rules.";
    };

    secretFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Environment file containing ET_NETWORK_SECRET=... (e.g. a sops secret path).";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra easytier-core command-line arguments.";
    };
  };
}

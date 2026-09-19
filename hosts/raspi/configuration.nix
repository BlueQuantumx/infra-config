# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  nixos-raspberrypi,
  inputs,
  defaults,
  ...
}:
{
  imports =
    with nixos-raspberrypi.nixosModules;
    [
      raspberry-pi-4.base
      raspberry-pi-4.bluetooth
    ]
    ++ [
      ./disko.nix
      ./hardware-configuration.nix
      ./sops.nix
      inputs.self.nixosModules.base
      inputs.self.nixosModules.prelude-linux
      inputs.self.nixosModules.overlays
      inputs.self.nixosModules.sops
      inputs.self.nixosModules.home-assistant
      inputs.self.nixosModules.wifi
      inputs.self.nixosModules.hust-network-login
      inputs.self.nixosModules.sing-box
      inputs.self.nixosModules.my-et-network
    ];

  # EasyTier mesh, kept as an optional fallback. Disabled by default through
  # defaults.easytier.enable; when off, neither the service nor its sops secret
  # is activated. Tailscale (below) is the active mesh.
  my-et-network = {
    enable = defaults.easytier.enable;
    ipv4 = defaults.easytier.raspi.ipv4;
    peers = [
      "tcp://${defaults.subdomains.azure}.${defaults.domain}:${toString (builtins.head defaults.easytier.tcpPorts)}"
    ];
    secretFile =
      if defaults.easytier.enable then config.sops.secrets."my-et-network/secret".path else null;
  };

  sops.secrets."my-et-network/secret" = lib.mkIf defaults.easytier.enable {
    sopsFile = ../../secrets/mesh.yaml;
  };

  # Tailscale enrollment key, minted by the tailnet OpenTofu stack and synced
  # into sops.
  sops.secrets."tailscale/authkey_raspi" = {
    sopsFile = ../../secrets/raspi.yaml;
  };

  # Tailscale: server node that advertises an exit node but does not consume
  # one. The sops-supplied auth key carries tag:server and tag:exit.
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale/authkey_raspi".path;
    useRoutingFeatures = "server";
    extraUpFlags = [ "--advertise-exit-node" ];
  };

  # Tie-break for the forwarding sysctl shared with Tailscale when the optional
  # EasyTier fallback is enabled (matches azure's identical note).
  boot.kernel.sysctl = lib.mkIf defaults.easytier.enable {
    "net.ipv4.conf.all.forwarding" = lib.mkForce true;
    "net.ipv6.conf.all.forwarding" = lib.mkForce true;
  };

  # My custom options
  my.hass = {
    activeInstance = "nju";
    instances.dffc = {
      configuration = ../modules/home-assistant/configuration.yaml;
      dataDir = "/var/lib/hass";
    };
    instances.nju = {
      configuration = ../modules/home-assistant/configuration.yaml;
      dataDir = "/var/lib/hass_nju";
    };
  };

  nix.settings = {
    experimental-features = "nix-command flakes";
    substituters = [ "https://nixos-raspberrypi.cachix.org" ];
  };

  # Case fan on GPIO14 (TXD), kernel gpio-fan overlay.
  hardware.raspberry-pi.config.all.dt-overlays.gpio-fan = {
    enable = true;
    params = {
      gpiopin = {
        enable = true;
        value = 14;
      };
      temp = {
        enable = true;
        value = 60000; # turn on at 60°C (millicelsius)
      };
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  users.users.luyan = {
    isNormalUser = true;
    linger = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
    initialHashedPassword = "";
    openssh.authorizedKeys.keys = defaults.hosts.raspi.adminKeys;
  };
  users.users.root = {
    openssh.authorizedKeys.keys = defaults.hosts.raspi.adminKeys;
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    helix
    git
    tree
  ];

  # Network Setup
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
  };

  # Wi-Fi Setup
  wifiNetworks = [
    {
      ssid = "Arknjghts";
      secretName = "wifi/arknjghts";
      key-mgmt = "wpa-psk";
    }
    {
      ssid = "dffc1102";
      secretName = "wifi/dffc1102";
      key-mgmt = "wpa-psk";
    }
  ];

  # Enable mDNS by avahi
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.addresses = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable Navidrome music server
  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      Address = "0.0.0.0";
      MusicFolder = "/srv/music";
    };
  };
  # music folder with correct permissions
  systemd.tmpfiles.rules = [
    "d /srv/music 0775 root users -"
  ];

  # Configure journald log rotation size
  environment.etc."systemd/journald.conf.d/99-size.conf".text = ''
    [Journal]
    SystemMaxUse=200M
    SystemKeepFree=50M
    SystemMaxFileSize=50M
  '';

  # Zsh
  programs.zsh = {
    enable = true;
  };

  # Integrate home-manager as a NixOS module
  home-manager.users.luyan.imports = [ ../../home-manager/luyan-raspi.nix ];
}

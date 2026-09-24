# Physical x86_64 desktop "529-2".
#
# Shared baseline (hostname, SSH hardening, admin user, flakes, overlays and
# sops) comes from hosts/modules; this file holds only desktop-specific deltas.
# This host was installed with the standard NixOS installer, so the disk layout
# lives in ./hardware-configuration.nix (no disko).
{
  pkgs,
  inputs,
  defaults,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./sops.nix
    inputs.self.nixosModules.base
    inputs.self.nixosModules.server
    inputs.self.nixosModules.overlays
    inputs.self.nixosModules.pascal-ddns
  ];

  # UEFI systemd-boot on the installer-created ESP.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Desktop tracks the latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # NetworkManager manages the wired/wireless interfaces.
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # GNOME desktop and X11 keymap.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  services.printing.enable = true;

  # PipeWire for sound, rtkit for realtime scheduling.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # The shared `server` module already creates `luyan` (wheel, zsh, SSH keys);
  # extend it with desktop-specific groups and packages.
  users.users.luyan = {
    description = defaults.identity.users.luyan.fullName;
    extraGroups = [ "networkmanager" ];
    packages = with pkgs; [
      neovim
    ];
  };

  home-manager.users.luyan.imports = [ ../../home-manager/luyan-529-2.nix ];

  programs.firefox.enable = true;

  # Report this desktop's addresses to Pascal DDNS. It sits on the campus
  # network, so it talks to the DDNS backend directly instead of via the public
  # HTTPS frontend.
  services.pascal-ddns = {
    enable = true;
    server = "http://pascal08.svr.pascal-lab.net:8788";
    secretFile = config.sops.secrets.pascal_ddns_auth.path;
  };
}

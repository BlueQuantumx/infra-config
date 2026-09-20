# PVE Portal 专用。不要删除本文件。
{ pkgs, lib, ... }:
{
  services.qemuGuest.enable = true;
  services.openssh.enable = lib.mkDefault true;
  services.openssh.settings.PermitRootLogin = lib.mkDefault "yes";
  services.openssh.settings.PasswordAuthentication = lib.mkDefault true;
  services.openssh.settings.KbdInteractiveAuthentication = lib.mkDefault true;
  services.fail2ban.enable = lib.mkDefault true;
  users.mutableUsers = lib.mkDefault true;
  security.sudo.wheelNeedsPassword = lib.mkDefault false;
  networking.hostName = lib.mkDefault "pascal-cloud";
  networking.useDHCP = lib.mkDefault true;
  boot.growPartition = lib.mkDefault true;
  boot.initrd.availableKernelModules = [
    "uas"
    "virtio_blk"
    "virtio_pci"
  ];
  boot.loader.grub.device = lib.mkDefault "/dev/vda";
  boot.loader.timeout = lib.mkDefault 0;
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };
  nix.settings.substituters = lib.mkDefault [
    "https://mirrors.pascal-lab.net/nix-channels/store"
    "https://cache.nixos.org"
  ];
  systemd.tmpfiles.rules = [
    "d /usr/sbin 0755 root root -"
    "L+ /usr/sbin/chpasswd - - - - ${pkgs.shadow}/bin/chpasswd"
    "L+ /bin/bash - - - - ${pkgs.bashInteractive}/bin/bash"
  ];
  environment.systemPackages = with pkgs; [ curl ];
  users.motd = lib.mkDefault ''
    ==========================================
           Welcome to the PASCAL Cloud
    ==========================================
    注意事项：
    1. 重要数据请随时备份
    2. 联网请执行 /server-scripts/njunet.sh
    3. 【不要删除对 /etc/pve-portal/nixos-module.nix 的导入】
    ==========================================
  '';
  # switch 会 SIGTERM cloud-init。runcmd 只用 boot+reboot；哨兵在第二次开机写。
  systemd.services.pve-portal-guest-init = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!/var/lib/pve-portal/guest-init.done";
    serviceConfig.Type = "oneshot";
    path = [
      pkgs.curl
      pkgs.gnutar
      pkgs.gzip
      pkgs.coreutils
      pkgs.nix
    ];
    script = ''
      set -eu
      ${pkgs.curl}/bin/curl -o /server-scripts.tar.gz https://box.nju.edu.cn/seafhttp/f/77a8ccfa9e4440bca365/?op=view
      ${pkgs.gnutar}/bin/tar -xzf /server-scripts.tar.gz -C /
      rm -f /server-scripts.tar.gz
      ${pkgs.nix}/bin/nix-collect-garbage -d
      mkdir -p /var/lib/pve-portal
      date -Is > /var/lib/pve-portal/guest-init.done
    '';
  };
}

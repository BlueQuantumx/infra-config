# Shared layout for cloud VMs: GRUB installed on the removable UEFI path and
# DHCP networking (hosts that provision addresses elsewhere force it off).
{ lib, ... }:
{
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.useDHCP = lib.mkDefault true;
}

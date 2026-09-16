{
  pkgs,
  lib,
  ...
}:

{
  imports = [
  ];

  options = {
    my.isRemote = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this configuration is for a remote machine.";
    };
  };

  config = {
    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";
    nix.settings.substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://nixos-raspberrypi.cachix.org"
    ];
    nix.gc = {
      automatic = true;
    };
  };
}

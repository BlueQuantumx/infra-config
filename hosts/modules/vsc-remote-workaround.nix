{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.my.isRemote) {
    programs = {
      nix-ld.enable = pkgs.stdenv.hostPlatform.isLinux;
    };
  };
}

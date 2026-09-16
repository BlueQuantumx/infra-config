# Shared user-level baseline for every home-manager profile.
# Per-profile files add programs (zsh, neovim, ...), identity and, for
# standalone profiles, the nixpkgs overlays.
{
  lib,
  defaults,
  ...
}:
{
  imports = [
    ./direnv.nix
    ./git.nix
  ];

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs.
  systemd.user.startServices = "sd-switch";

  home.stateVersion = lib.mkDefault defaults.stateVersion;
}

{
  inputs,
  ...
}:
{
  imports = [
    ./modules/base.nix
    ./modules/zsh.nix
  ];

  # Standalone profile: no system nixpkgs to inherit, so declare overlays here.
  nixpkgs = {
    overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  home = {
    username = "zly";
    homeDirectory = "/home/zly";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}

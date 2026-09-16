{
  defaults,
  ...
}:
{
  imports = [
    ./modules/base.nix
    ./modules/zsh.nix
  ];

  home = {
    username = "luyan";
    homeDirectory = defaults.identity.users.luyan.home.linux;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}

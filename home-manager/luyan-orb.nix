{
  defaults,
  ...
}:
{
  imports = [
    ./modules/base.nix
  ];

  home = {
    username = "luyan";
    homeDirectory = defaults.identity.users.luyan.home.linux;
    stateVersion = "25.11";
  };

  programs.bash.enable = true;
}

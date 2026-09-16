{ ... }:
{
  imports = [
    ./vsc-remote-workaround.nix
  ];

  config = {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };
  };
}

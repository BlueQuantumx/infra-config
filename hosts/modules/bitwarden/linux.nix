# Linux half of the Bitwarden module: install the nixpkgs package, which is a
# plain install in the home directory, and point SSH_AUTH_SOCK at the socket
# that build creates. Imported with `inputs.self.nixosModules.bitwarden`.
{
  config,
  pkgs,
  lib,
  defaults,
  ...
}:
let
  cfg = config.my.bitwarden;

  # Identity and home directories are declared once in defaults.nix.
  home = defaults.identity.users.${defaults.identity.adminUser}.home.linux;
in
{
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.bitwarden-desktop ];

    # mkDefault, so a host may point SSH_AUTH_SOCK at another agent (gpg-agent,
    # for one) without having to disable this module. A Flatpak or snap build
    # keeps its socket elsewhere, which is what `my.bitwarden.socket` overrides
    # this default with.
    environment.variables.SSH_AUTH_SOCK = lib.mkDefault (
      if cfg.socket != null then cfg.socket else "${home}/.bitwarden-ssh-agent.sock"
    );
  };
}

# Bitwarden Desktop doubles as an SSH agent: the vault holds the private keys and
# the app serves them over a unix socket. That socket only exists while the app
# runs with Settings -> "Enable SSH agent" turned on, so using the agent is a
# matter of pointing SSH_AUTH_SOCK at it.
#
# The platform-dependent halves live next to this file: `macos.nix` installs the
# App Store build and reads the sandbox container socket, `linux.nix` installs
# the nixpkgs package and reads the home directory socket.
{ lib, ... }:
{
  options.my.bitwarden = {
    enable = lib.mkEnableOption "Bitwarden Desktop, with its SSH agent wired up";

    socket = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Absolute path of the Bitwarden SSH agent socket, for installations whose
        socket is not at the location implied by the platform and the default
        install layout: the Flatpak build uses
        `~/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock`, the
        snap build `~/snap/bitwarden/current/.bitwarden-ssh-agent.sock`, and a
        macOS .dmg build `~/.bitwarden-ssh-agent.sock`.
      '';
    };
  };
}

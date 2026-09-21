# macOS half of the Bitwarden module: install the App Store build through
# Homebrew's `mas`, and point SSH_AUTH_SOCK at the sandbox container socket that
# build creates. Imported with `inputs.self.darwinModules.bitwarden`.
{
  config,
  lib,
  defaults,
  ...
}:
let
  cfg = config.my.bitwarden;

  # Identity and home directories are declared once in defaults.nix.
  home = defaults.identity.users.${defaults.identity.adminUser}.home.darwin;
in
{
  imports = [
    ./options.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # environment.variables reaches shells (through /etc/zshenv and
      # /etc/bashrc), not GUI apps, which keep the socket launchd handed them:
      # git and ssh in a terminal use the vault keys, while an IDE launched from
      # the Dock still uses the system agent.
      #
      # mkDefault, so a host may point SSH_AUTH_SOCK at another agent
      # (gpg-agent, for one) without having to disable this module. The App
      # Store build keeps its socket in the sandbox container; a .dmg build
      # keeps it in the home directory, which is what `my.bitwarden.socket`
      # overrides this default with.
      environment.variables.SSH_AUTH_SOCK = lib.mkDefault (
        if cfg.socket != null then
          cfg.socket
        else
          "${home}/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
      );

      # `com.bitwarden.desktop` ships through the App Store only, and Homebrew's
      # Brewfile is what drives `mas`.
      #
      # mas must be resolvable from the PATH brew starts with: Homebrew Bundle
      # looks it up with `which(mas, ORIGINAL_PATHS)`. nix-darwin arranges that
      # by prepending its own mas to the activation PATH, and declaring the `mas`
      # formula in `homebrew.brews` arranges it for a login shell. Without a
      # reachable mas, brew falls back to `brew install mas`, re-checks the same
      # PATH, and aborts activation with "Unable to install <app> app. mas
      # installation failed.".
      #
      # Both mas 6 and mas 7 document `install`/`update` as requiring root, while
      # brew bundle runs mas as the login user: an app that is already installed
      # and up to date is skipped, but a pending App Store update has to be
      # applied from the App Store itself.
      homebrew.masApps = {
        bitwarden = 1352778147;
      };
    })

    # Declaring an App Store app does nothing while Homebrew is off, which would
    # leave the app missing without a word.
    {
      assertions = lib.optional cfg.enable {
        assertion = config.homebrew.enable;
        message = "my.bitwarden.enable needs homebrew.enable to install Bitwarden from the App Store on macOS.";
      };
    }
  ];
}

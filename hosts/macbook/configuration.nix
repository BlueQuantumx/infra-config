{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.prelude
    inputs.self.darwinModules.homebrew
  ];
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    tinymist
    uv
    just
    helix
    swift-format
    bun
    gh
    corepack
    pdfpc
  ];
  homebrew.brews = [
    "hermes-agent"
    # omp — the `can1357/oh-my-pi` coding agent. Fully-qualified name makes
    # Homebrew Bundle tap `can1357/tap` and trust it on activation.
    "can1357/tap/omp"
    "opencode"
    "openspec"
    "pi-coding-agent"
  ];
  homebrew.casks = [
    "android-studio"
    "betterdisplay"
    "bilibili"
    "hermes-desktop"
    "iina"
    "intellij-idea"
    "jetbrains-gateway"
    "keka"
    "maa"
    "mac-mouse-fix"
    "microsoft-edge"
    "mysql-shell"
    "obsidian"
    "orbstack"
    "pearcleaner"
    "rectangle"
    "sfm"
    "stats"
    "visual-studio-code"
    "xcodes-app"
    "zed"
    "zotero"
  ];


  nix.settings.trusted-users = [
    "root"
    "luyan"
  ];

  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
  };

  system.defaults = {
    finder = {
      FXPreferredViewStyle = "Nlsv";
      AppleShowAllExtensions = true;
    };
    ".GlobalPreferences"."com.apple.mouse.scaling" = 0.7;
    NSGlobalDomain."com.apple.trackpad.scaling" = 1.0;
  };
  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
  system.primaryUser = "luyan";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}

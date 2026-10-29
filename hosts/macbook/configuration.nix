{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.base
    inputs.self.nixosModules.prelude
    inputs.self.nixosModules.overlays
    inputs.self.darwinModules.homebrew
    inputs.self.darwinModules.bitwarden
  ];
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "bws"
    ];
  environment.systemPackages = with pkgs; [
    bun
    bws
    corepack
    gh
    helix
    just
    just-formatter
    just-lsp
    pdfpc
    rustup
    sops
    swift-format
    tinymist
    typst
    uv
  ];
  homebrew.brews = [
    "bitwarden-cli"
    # duplicate of `hermes-desktop` cask, which includes the `hermes-agent` binary.
    # "hermes-agent"
    "mas"
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
    "block-goose"
    "deepseek-harness"
    "hermes-desktop"
    "iina"
    "intellij-idea"
    "jetbrains-gateway"
    "karabiner-elements"
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
    "telegram"
    "visual-studio-code"
    "xcodes-app"
    "zed"
    "zotero"
  ];
  homebrew.masApps = {
    QQ = 451108668;
    WeChat = 836500024;
    NeteaseCloudMusic = 944848654;
    Feishu = 1551632588;
    ImmersiveTranslate = 6447957425;
    Amphetamine = 937984704;
    TestFlight = 899247664;
  };

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
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 2;
    };
    dock = {
      wvous-bl-corner = 4;
      wvous-br-corner = 4;
      wvous-tl-corner = 2;
      wvous-tr-corner = 2;
    };
    universalaccess.mouseDriverCursorSize = 1.5;
    controlcenter.BatteryShowPercentage = true;
    ".GlobalPreferences"."com.apple.mouse.scaling" = 0.7;
    NSGlobalDomain."com.apple.trackpad.scaling" = 1.0;
    NSGlobalDomain."com.apple.keyboard.fnState" = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 25;
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain.NSStatusItemSpacing = 12;
  };
  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
  system.primaryUser = "luyan";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  my.bitwarden = {
    enable = true;
  };
}

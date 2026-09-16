{ inputs, ... }:
let
  nix-homebrew = inputs.nix-homebrew;
in
{
  imports = [
    nix-homebrew.darwinModules.nix-homebrew
    {
      nix-homebrew = {
        # Install Homebrew under the default prefix
        enable = true;

        # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
        enableRosetta = false;

        # User owning the Homebrew prefix
        user = "luyan";

        # Automatically migrate existing Homebrew installations
        autoMigrate = true;
      };
    }
  ];

  # homebrew configurations
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true; # 在 darwin-rebuild switch 时自动执行 brew update
      upgrade = true; # 在 darwin-rebuild switch 时自动执行 brew upgrade
      # "zap" 会自动卸载掉所有“未在下面 Nix 代码中声明”的 Brew 软件、Cask 和 Tap
      # 如果担心以前手动装的软件被删，可以先改成 "uninstall" 或 "none"
      cleanup = "none";
    };
  };
}

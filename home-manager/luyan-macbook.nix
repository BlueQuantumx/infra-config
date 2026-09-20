# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  pkgs,
  inputs,
  defaults,
  ...
}:
let
  # Absolute path to this repository: `nh` builds from a mutable flake path,
  # so a store copy of the flake would not track edits.
  repoFlake = "/Users/luyan/Projects/infra-config";
in
{
  # You can import other home-manager modules here
  imports = [
    # Shared baseline (direnv, git, home-manager.enable)
    ./modules/base.nix

    # macOS-only modules
    ./modules/rectangle.nix
    ./modules/ghostty.nix
    ./modules/xcode.nix
    ./modules/zsh.nix
    ./modules/github-token.nix
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
    username = "luyan";
    homeDirectory = defaults.identity.users.luyan.home.darwin;

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      font-awesome
    ];
  };

  # nh wraps `darwin-rebuild` / `home-manager switch`, resolving this repo's
  # flake and target from any working directory.
  programs.nh = {
    enable = true;
    flake = repoFlake;
    # Automatic GC is already provided by nix.gc.automatic in the host prelude,
    # so programs.nh.clean stays disabled to avoid a second schedule.
  };

  programs.opencode = {
    enable = true;
    settings = {
      "lsp" = true;
    };
  };

  programs.xcode = {
    enable = true;
    keybindings = {
      "Custom.idekeybindings" = ./keymaps/xcode/Custom.idekeybindings;
    };
  };

  programs.ssh = {
    enable = true;
    # unstable 推荐关闭旧默认，自己控制 Host * 配置
    enableDefaultConfig = false;
    # OrbStack 的 Include 需要放在所有 Host 块之前
    includes = [ "~/.orbstack/ssh/config" ];
    # 所有 host 默认：自动添加到 agent 并使用 macOS Keychain
    settings."*" = {
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
    };

    settings."github.com" = {
      HostName = "ssh.github.com";
      Port = 443;
      User = "git";
    };

    settings."raspberrypi" = {
      HostName = "louis-raspi.local";
      User = "luyan";
      Port = 22;
      ForwardAgent = true;
      IdentityFile = "~/.ssh/raspberrypi";
    };

    settings."raspi-ts" = {
      HostName = "louis-raspi.${defaults.tailnet.magicDnsDomain}";
      User = "luyan";
      Port = 22;
      ForwardAgent = true;
      IdentityFile = "~/.ssh/raspberrypi";
    };

    settings."orb-amd64" = {
      HostName = "ubuntu-amd64.orb.local";
      Port = 32222;
      User = "luyan@ubuntu-amd64";
      IdentityFile = "~/.orbstack/ssh/id_ed25519";
      ForwardAgent = true;
      RemoteForward = "/run/user/501/gnupg/S.gpg-agent /home/luyan/.gnupg/S.gpg-agent.extra";
      IdentitiesOnly = true;
      ProxyCommand = "'/Applications/OrbStack.app/Contents/Frameworks/OrbStack Helper.app/Contents/MacOS/OrbStack Helper' ssh-proxy-fdpass 501";
      ProxyUseFdpass = true;
    };

    settings."azure" = {
      HostName = "azure.egrecho47.top";
      User = "luyan";
      ForwardAgent = true;
      IdentityFile = "~/.ssh/azure";
    };

    settings."huawei-cloud" = {
      HostName = "1.92.75.149";
      User = "luyan";
    };

    settings."tencent-cloud" = {
      HostName = "www.zlxxwy.cn";
      User = "administrator";
    };

    settings."pascal06" = {
      HostName = "pascal06.svr.pascal-lab.net";
      User = "zly";
      IdentityFile = "~/.ssh/pascal";
      ForwardAgent = true;
    };

    settings."pascal-cloud-01" = {
      HostName = "114.212.81.76";
      User = "root";
      IdentityFile = "~/.ssh/pascal";
      ForwardAgent = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}

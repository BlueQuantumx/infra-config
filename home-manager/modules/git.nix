{ lib, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    ignores = [
      ".DS_Store"
      ".direnv/"
    ];

    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINUPT6A9p1/DKyY0cvq2li9ytDDXEy2tr+1p1Q5R0XUF";
      signByDefault = true;
    };

    # 用户信息
    settings = {
      user.name = lib.mkDefault "Luyan Zhou";
      user.email = lib.mkDefault "78394824+BlueQuantumx@users.noreply.github.com";
    };
  };
}

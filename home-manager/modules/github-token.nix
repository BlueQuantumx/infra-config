{ config, inputs, ... }:
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    # sops asserts key must be set
    age.sshKeyPaths = [ "/Users/luyan/.ssh/sops" ];

    # sops-install-secrets 内嵌的 sops 库无法用 age.sshKeyPaths 转出的
    # AGE-SECRET-KEY 匹配 ssh-ed25519 recipient（报 0 successful groups）。
    # 让 sops 走原生 ssh 私钥直读路径（getsops 读取 SOPS_AGE_SSH_PRIVATE_KEY_FILE）。
    environment.SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/Users/luyan/.ssh/sops";

    secrets."github_token" = {
      sopsFile = ../../secrets/macbook.yaml;
      key = "github_token";
    };

    templates."github-env" = {
      content = ''
        export GITHUB_TOKEN=${config.sops.placeholder."github_token"}
      '';
    };
  };

  programs.zsh.initContent = ''
    if [ -f ${config.sops.templates."github-env".path} ]; then
      source ${config.sops.templates."github-env".path}
    fi
  '';
}

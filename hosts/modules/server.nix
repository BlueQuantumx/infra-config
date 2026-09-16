{ pkgs, defaults, hostName, ... }:
let
  adminUser = defaults.identity.adminUser;
  adminKeys = defaults.hosts.${hostName}.adminKeys;
in
{
  # Hardened sshd: keys only, root login via key.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Grant admin access to both root and the admin user from one key list.
  users.users.root.openssh.authorizedKeys.keys = adminKeys;
  users.users.${adminUser} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = adminKeys;
  };

  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}

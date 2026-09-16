{
  modulesPath,
  lib,
  pkgs,
  inputs,
  defaults,
  ...
} @ args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./digitalocean.nix
    inputs.self.nixosModules.base
    inputs.self.nixosModules.cloud-vm
    inputs.self.nixosModules.overlays
  ];

  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys =
    defaults.hosts.digitalocean.adminKeys ++ (args.extraPublicKeys or [ ]);

  # This host predates the current state version; never change it.
  system.stateVersion = "24.05";
}

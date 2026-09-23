{
  inputs,
  ...
}:
{
  imports = [
    ./sops.nix
    ../modules/pve-portal.nix
    inputs.self.nixosModules.base
    inputs.self.nixosModules.server
    # inputs.self.nixosModules.cloud-vm
    inputs.self.nixosModules.overlays
    inputs.self.nixosModules.sops
    inputs.self.nixosModules.prelude-linux
  ];

  # Integrate home-manager as a NixOS module
  home-manager.users.luyan.imports = [ ../../home-manager/luyan-pascal-cloud.nix ];
}

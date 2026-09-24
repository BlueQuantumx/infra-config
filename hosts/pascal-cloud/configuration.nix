{
  config,
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
    inputs.self.nixosModules.pascal-ddns
  ];

  nixpkgs = {
    overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  # Publish this cloud VM's address as zly.svr.pascal-lab.net -- the Pascal DDNS
  # entry this host reuses -- reached through the service's public HTTPS
  # frontend.
  services.pascal-ddns = {
    enable = true;
    secretFile = config.sops.secrets.pascal_ddns_auth.path;
  };

  # Integrate home-manager as a NixOS module
  home-manager.users.luyan.imports = [ ../../home-manager/luyan-pascal-cloud.nix ];
}

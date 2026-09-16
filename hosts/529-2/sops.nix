# sops wiring for "529-2".
#
# The host has its own secrets file, encrypted to the admin key and this host's
{ inputs, ... }:
{
  imports = [
    inputs.self.nixosModules.sops
  ];
  sops.defaultSopsFile = ../../secrets/529-2.yaml;
  sops.secrets."pascal_ddns_auth" = { };
}

{ lib, defaults, hostName, ... }:
let
  host = defaults.hosts.${hostName};
in
{
  imports = [
    ./prelude.nix
  ];

  config = lib.mkMerge [
    {
      system.stateVersion = lib.mkDefault defaults.stateVersion;

      # Whether this host needs the VSCode remote (nix-ld) workaround.
      my.isRemote = host.isRemote;
    }

    (lib.mkIf (host.hostname != null) {
      networking.hostName = lib.mkDefault host.hostname;
    })
  ];
}

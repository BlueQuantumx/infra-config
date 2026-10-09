{
  lib,
  defaults,
  hostName,
  ...
}:
let
  host = defaults.hosts.${hostName};
in
lib.mkIf (host.hostname != null) {
  networking = {
    localHostName = lib.mkDefault host.hostname;
    computerName = lib.mkDefault host.hostname;
  };
}

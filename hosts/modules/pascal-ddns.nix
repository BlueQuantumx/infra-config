# Pascal DDNS reporter.
#
# Every host owns one entry on the Pascal DDNS service (ddns.pascal-lab.net);
# the entry's `report_uuid` doubles as the bearer token that authorises reports
# for that entry only, so the token is a per-host secret. The service itself
# picks the address to publish from the reported interface list (an entry may
# pin a preferred interface MAC server-side), hence the module reports `ip a`
# verbatim instead of pre-selecting an address.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.pascal-ddns;

  # A trailing slash in `server` would yield `//api/v1/report`.
  server = lib.removeSuffix "/" cfg.server;

  report = pkgs.writeShellScript "pascal-ddns-report" ''
    set -eu
    token="$(< ${cfg.secretFile})"
    [ -n "$token" ]
    ${pkgs.iproute2}/bin/ip a | ${pkgs.curl}/bin/curl -fsS -X POST ${server}/api/v1/report \
      -H "Authorization: Bearer $token" \
      -H 'Content-Type: text/plain; charset=utf-8' \
      --data-binary @- >/dev/null
  '';
in
{
  options.services.pascal-ddns = {
    enable = lib.mkEnableOption "reporting this host's addresses to Pascal DDNS";

    server = lib.mkOption {
      type = lib.types.str;
      default = "https://ddns.pascal-lab.net";
      example = "http://pascal08.svr.pascal-lab.net:8788";
      description = ''
        Base URL of the DDNS service; `/api/v1/report` is appended to it.
      '';
    };

    secretFile = lib.mkOption {
      type = lib.types.str;
      example = "/run/secrets/pascal_ddns_auth";
      description = ''
        File holding the `report_uuid` of this host's DDNS entry. sops-nix hosts
        pass `config.sops.secrets.<name>.path`; the file is read by the unit and
        never copied into the store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pascal-ddns = {
      description = "Report this host's addresses to Pascal DDNS";

      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = report;
      };
    };

    systemd.timers.pascal-ddns = {
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "0";
        OnUnitActiveSec = "5min";
      };
    };
  };
}

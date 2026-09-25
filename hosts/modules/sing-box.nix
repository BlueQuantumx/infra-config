# sing-box client module: keeps a sing-box instance running against a
# configuration downloaded from a subscription URL, refreshed on a timer.
#
# It builds on nixpkgs' `services.sing-box` rather than re-implementing it: the
# module enables that service and adds the download machinery, so the unit's
# binary, capabilities, reload command and file layout stay upstream's. The one
# contract it leans on is that nixpkgs starts sing-box as
#
#   sing-box -D $STATE_DIRECTORY -C $CONFIGURATION_DIRECTORY run
#
# while `settings` is empty, i.e. sing-box loads every configuration file in
# /etc/sing-box -- which is where the download writes its file. That keeps the
# ExecStart of the unit untouched.
#
# Nothing here is host-specific: the subscription URL is read from a file the
# host points at (`my.singbox.secretFile`), so with sops-nix the host passes
# `config.sops.secrets.<name>.path` and the module stays independent of both the
# host and the secret store. A host enables the module with
# `my.singbox.enable = true;`.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.singbox;
  singbox = config.services.sing-box;

  # The sing-box unit's ConfigurationDirectory, i.e. the directory its ExecStart
  # hands to `-C`.
  configFile = "/etc/sing-box/config.json";

  downloadScript = pkgs.writeShellScript "download-singbox-subscription" (
    builtins.readFile ./sing-box/download.sh
  );
in
{
  options.my.singbox = {
    enable = lib.mkEnableOption "sing-box, configured from a subscription URL";

    secretFile = lib.mkOption {
      type = lib.types.str;
      example = "/run/secrets/singbox/subscription_url";
      description = ''
        File holding this host's subscription URL. sops-nix hosts pass
        `config.sops.secrets.<name>.path`; the file is read by the unit at
        runtime and never copied into the store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.download-singbox-subscription = {
      description = "Download sing-box subscription";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = downloadScript;
        Environment = [
          "SINGBOX_SECRET_FILE=${cfg.secretFile}"
          "SINGBOX_CONFIG_FILE=${configFile}"
        ];
      };

      path = [
        pkgs.curl
        pkgs.jq
        pkgs.coreutils
        # `sing-box check` runs the same binary the service runs.
        singbox.package
      ];
    };

    systemd.services.update-singbox-subscription = {
      description = "Update sing-box subscription";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "update-singbox-subscription" ''
          ${pkgs.systemd}/bin/systemctl restart download-singbox-subscription.service

          # SIGHUP is sing-box's reload, but a SIGHUP delivered before sing-box
          # has installed its handler -- for instance while the unit is still
          # starting because activation restarted it -- kills it, and
          # `Restart = "no"` would leave it down. So reload, then make sure it
          # ends up running: `start` is a no-op on a healthy unit and brings a
          # dead one back up on the configuration just downloaded.
          ${pkgs.systemd}/bin/systemctl reload sing-box.service || true
          ${pkgs.systemd}/bin/systemctl start sing-box.service
        '';
      };
    };

    systemd.timers.update-singbox-subscription = {
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1h";
        Persistent = true;
      };
    };

    # Enables nixpkgs' unit as-is; see the header comment for why `settings` has
    # to stay empty (a non-empty `settings` would move `-C` to /run/sing-box and
    # shadow the downloaded file).
    services.sing-box.enable = true;

    systemd.services.sing-box = {
      # The downloaded configuration has to exist before sing-box starts:
      # sing-box treats a missing or empty `-C` directory as fatal, so the
      # download (which always leaves a file behind, `{}` included) has to have
      # run at least once.
      after = [
        "network-online.target"
        "download-singbox-subscription.service"
      ];

      wants = [
        "download-singbox-subscription.service"
        "network-online.target"
      ];

      serviceConfig = {
        # A configuration `sing-box check` accepts can still fail at runtime
        # (rule-set fetches, TUN setup). Upstream restarts 10s after a failure,
        # which never trips systemd's start limit and would loop forever, so
        # leave recovery to the hourly refresh instead.
        Restart = "no";
      };
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}:

{
  sops.secrets."singbox/subscription_url" = {
    sopsFile = ../../secrets/raspi.yaml;
  };

  networking.firewall.allowedTCPPorts = [ 60123 ];

  systemd.services.download-singbox-subscription = {
    description = "Download sing-box subscription";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "download-singbox-subscription" (
        builtins.readFile ./sing-box/download.sh
      );
    };
    path = with pkgs; [
      curl
      jq
      coreutils
      systemd
      sing-box
    ];
  };

  systemd.services.update-singbox-subscription = {
    description = "Update sing-box subscription";

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "update-singbox-subscription" (''
        ${pkgs.systemd}/bin/systemctl restart download-singbox-subscription.service
        ${pkgs.systemd}/bin/systemctl reload sing-box.service
      '');
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

  services.sing-box = {
    enable = true;
  };

  systemd.services.sing-box = {
    serviceConfig = {
      ExecStart = lib.mkForce [
        # empty item will clear the ExecStart, this is a systemd standard way to override
        ""
        ''
          ${pkgs.sing-box}/bin/sing-box run \
            -c /var/lib/sing-box/config.json
        ''
      ];
      Restart = "no";
    };

    after = [
      "network-online.target"
      "download-singbox-subscription.service"
    ];

    wants = [
      "download-singbox-subscription.service"
      "network-online.target"
    ];
  };
}

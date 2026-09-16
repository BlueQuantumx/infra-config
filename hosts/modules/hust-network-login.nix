{ config, pkgs, lib, ... }:
let
  cfg = config.services.hust-network-login;
in
{
  options.services.hust-network-login = {
    enable = lib.mkEnableOption "HUST network login service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../pkgs/hust-network-login/default.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ../../pkgs/hust-network-login/default.nix { }";
      description = "Package used by the service.";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the configuration file containing account on the first line and password on the second line.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.hust-network-login = {
      description = "HUST network login";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      unitConfig = {
        StartLimitBurst = 5;
        StartLimitIntervalSec = 60;
      };

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/hust-network-login ${cfg.configFile}";
        Restart = "on-failure";
        RestartSec = 5;
      };

      wantedBy = [ "multi-user.target" ];
    };
  };
}

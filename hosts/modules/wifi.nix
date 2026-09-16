{ config, lib, ... }:
let
  #
  # 把 wifi/home 转成 WIFI_HOME
  #
  secretToEnv = secret: lib.toUpper (builtins.replaceStrings [ "/" "-" "." ] [ "_" "_" "_" ] secret);
in
{
  options.wifiNetworks = lib.mkOption {
    type =
      with lib.types;
      # 每个列表项是一个属性集，属性值均为字符串
      listOf (attrsOf str);
    default = [ ];
  };

  config = {
    sops.secrets = lib.listToAttrs (
      map (wifi: {
        name = wifi.secretName;
        value = { };
      }) config.wifiNetworks
    );

    #
    # 生成 environment file
    #
    sops.templates."wifi-env" = {
      content = lib.concatLines (
        map (
          wifi:
          let
            envName = secretToEnv wifi.secretName;
          in
          "${envName}=${config.sops.placeholder.${wifi.secretName}}"
        ) config.wifiNetworks
      );
    };

    networking.networkmanager = {
      enable = true;

      ensureProfiles = {
        environmentFiles = [ config.sops.templates."wifi-env".path ];
        profiles = lib.listToAttrs (
          map (wifi: {
            name = wifi.ssid;
            value = {
              connection = {
                id = wifi.ssid;
                type = "wifi";
              };

              wifi = {
                ssid = wifi.ssid;
                mode = "infrastructure";
              };

              wifi-security = {
                # auth-alg = "open";
                key-mgmt = wifi.key-mgmt;
                psk = "\$${secretToEnv wifi.secretName}";
              };

              ipv4.method = "auto";
              ipv6.method = "auto";
            };
          }) config.wifiNetworks
        );
      };
    };
  };
}

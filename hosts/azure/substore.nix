{
  config,
  lib,
  ...
}:

let
  defaults = import ../../defaults.nix;
  backendPath =
    let
      v = config.sops.placeholder.backend_path;
    in
    if lib.hasPrefix "/" v then v else "/${v}";
  templates = ./substore-templates;
  mkSingboxFile =
    version: name: displayName: mode:
    lib.recursiveUpdate {
      displayName = displayName;
      source = "local";
      sourceType = "collection";
      type = "file";
      # Remote-device templates carry an auth-key token that is replaced here
      # with a sops placeholder. sops-install-secrets substitutes the real key
      # when the files.json template is rendered; the key never lands in git.
      content = lib.replaceStrings
        [
          "__TAILSCALE_AUTHKEY_MAC__"
          "__TAILSCALE_AUTHKEY_IOS__"
          "__TAILSCALE_AUTHKEY_LINUX_DESKTOP__"
        ]
        [
          config.sops.placeholder."tailscale/authkey_mac"
          config.sops.placeholder."tailscale/authkey_ios"
          config.sops.placeholder."tailscale/authkey_linux_desktop"
        ]
        (builtins.readFile (templates + "/${version}/${name}.json"));
      process = scriptOperator (builtins.readFile "${templates}/scripts/inject-proxies.js");
    } (lib.optionalAttrs (mode != null) { inherit mode; });
  scriptOperator = scriptContent: [
    {
      type = "Script Operator";
      args = {
        content = scriptContent;
        mode = "script";
        arguments = { };
      };
    }
  ];
  quickSettings = [
    {
      type = "Quick Setting Operator";
      args = {
        useless = "DISABLED";
        udp = "DEFAULT";
        scert = "DEFAULT";
        tfo = "DEFAULT";
        "vmess aead" = "DEFAULT";
      };
    }
  ];
in
{
  networking.firewall.allowedTCPPorts = [
    80 # ACME challenge + redirect
    443 # HTTPS
  ];

  sops.secrets = {
    backend_path = { };
    push_service_base_url = { };
    "subs/hutao_cloud_url" = { };
    "subs/liangxinyun_url" = { };
    "subs/holytech_url" = { };
  };

  sops.templates = {
    "sub-store.env" = {
      path = "/run/secrets/sub-store.env";
      content = ''
        SUB_STORE_FRONTEND_BACKEND_PATH=${backendPath}
        SUB_STORE_PUSH_SERVICE=${config.sops.placeholder.push_service_base_url}/[推送标题]/[推送内容]?group=SubStore&isArchive=1&level=timeSensitive
      '';
      restartUnits = [
        "sub-store.service"
        "sub-store-sync.service"
      ];
    };
    "subs.json" = {
      path = "/run/secrets/subs.json";
      content = config.services.substore.renderedSubsJson;
      owner = "sub-store";
      group = "sub-store";
      mode = "0440";
      restartUnits = [ "sub-store-sync.service" ];
    };
    "files.json" = {
      path = "/run/secrets/files.json";
      content = config.services.substore.renderedFilesJson;
      owner = "sub-store";
      group = "sub-store";
      mode = "0440";
      restartUnits = [ "sub-store-sync.service" ];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."${defaults.subdomains.substore}.${defaults.domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.substore.backendPort}
      '';
    };
  };

  services.substore = {
    enable = true;
    backendMerge = true;
    environmentFile = config.sops.templates."sub-store.env".path;
    payloadPath = "/run/secrets";

    subscriptions = {
      hutao_cloud = {
        displayName = "Hutao Cloud";
        source = "remote";
        url = config.sops.placeholder."subs/hutao_cloud_url";
        ua = "GUI.for.Singbox/v1.23.2";
        process = quickSettings;
        extraOptions = {
          tag = [ "Backup" ];
          passThroughUA = false;
          ignoreFailedRemoteSub = "enabled";
        };
      };

      liangxinyun = {
        displayName = "良心云";
        source = "remote";
        url = config.sops.placeholder."subs/liangxinyun_url";
        process = quickSettings;
        extraOptions = {
          tag = [ "Backup" ];
          passThroughUA = false;
          ignoreFailedRemoteSub = "enabled";
        };
      };

      holytech = {
        displayName = "holytech";
        source = "remote";
        url = config.sops.placeholder."subs/holytech_url";
        process = quickSettings;
        extraOptions = {
          tag = [ "Main" ];
          passThroughUA = false;
          ignoreFailedRemoteSub = "enabled";
        };
      };
    };

    files = {
      linux_headless_1_13 = mkSingboxFile "1.13" "linux-headless" "Linux Headless (sing-box 1.13)" null;
      linux_headless_1_14 = mkSingboxFile "1.14" "linux-headless" "Linux Headless (sing-box 1.14)" null;
      linux_desktop_1_13 = mkSingboxFile "1.13" "linux-desktop" "Linux Desktop (sing-box 1.13)" "config";
      linux_desktop_1_14 = mkSingboxFile "1.14" "linux-desktop" "Linux Desktop (sing-box 1.14)" "config";
      mac_1_13 = mkSingboxFile "1.13" "mac" "Mac (sing-box 1.13)" "config";
      mac_1_14 = mkSingboxFile "1.14" "mac" "Mac (sing-box 1.14)" "config";
      ios_1_13 = mkSingboxFile "1.13" "ios" "iOS (sing-box 1.13)" "config";
      ios_1_14 = mkSingboxFile "1.14" "ios" "iOS (sing-box 1.14)" "config";
    };
  };
}

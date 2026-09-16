{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.substore;

  subOptions = { ... }: {
    options = {
      displayName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      source = lib.mkOption {
        type = lib.types.enum [
          "local"
          "remote"
        ];
        default = "remote";
      };
      url = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      mergeSources = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "localFirst"
            "remoteFirst"
          ]
        );
        default = null;
      };
      subUserinfo = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      noFlow = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      proxy = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      ua = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      includeUnsupportedProxy = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
      };
      process = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.anything);
        default = null;
      };
      extraOptions = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
      };
    };
  };

  fileOptions = { ... }: {
    options = {
      displayName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      source = lib.mkOption {
        type = lib.types.enum [
          "local"
          "remote"
        ];
        default = "remote";
      };
      url = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      content = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      type = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      sourceType = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "subscription"
            "collection"
            "local"
            "remote"
            "none"
            "url"
          ]
        );
        default = null;
      };
      sourceName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      mode = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      mergeSources = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "localFirst"
            "remoteFirst"
          ]
        );
        default = null;
      };
      ignoreFailedRemoteFile = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
      };
      includeUnsupportedProxy = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
      };
      subInfoUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      subInfoUserAgent = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      proxy = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      ua = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      noCache = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
      };
      process = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.anything);
        default = null;
      };
      extraOptions = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
      };
    };
  };

  renderSub =
    name: sub:
    (lib.filterAttrs (n: v: v != null) {
      displayName = sub.displayName;
      source = sub.source;
      url = sub.url;
      mergeSources = sub.mergeSources;
      subUserinfo = sub.subUserinfo;
      noFlow = if sub.noFlow then true else null;
      proxy = sub.proxy;
      ua = sub.ua;
      includeUnsupportedProxy = sub.includeUnsupportedProxy;
      process = sub.process;
    })
    // sub.extraOptions
    // {
      inherit name;
    };

  renderFile =
    name: file:
    (lib.filterAttrs (n: v: v != null) {
      displayName = file.displayName;
      source = file.source;
      url = file.url;
      content = file.content;
      type = file.type;
      sourceType = file.sourceType;
      sourceName = file.sourceName;
      mode = file.mode;
      mergeSources = file.mergeSources;
      ignoreFailedRemoteFile = file.ignoreFailedRemoteFile;
      includeUnsupportedProxy = file.includeUnsupportedProxy;
      subInfoUrl = file.subInfoUrl;
      subInfoUserAgent = file.subInfoUserAgent;
      proxy = file.proxy;
      ua = file.ua;
      noCache = file.noCache;
      process = file.process;
    })
    // file.extraOptions
    // {
      inherit name;
    };

  subsJson = lib.generators.toJSON { } (lib.mapAttrsToList renderSub cfg.subscriptions);
  filesJson = lib.generators.toJSON { } (lib.mapAttrsToList renderFile cfg.files);

  subsPayload = pkgs.writeText "sub-store-subs.json" subsJson;
  filesPayload = pkgs.writeText "sub-store-files.json" filesJson;

  syncScript = pkgs.writeShellScript "sub-store-sync" ''
    set -euo pipefail
    if [ -n "${cfg.payloadPath}" ]; then
      subsFile="${cfg.payloadPath}/subs.json"
      filesFile="${cfg.payloadPath}/files.json"
    else
      subsFile=${subsPayload}
      filesFile=${filesPayload}
    fi
    ${pkgs.curl}/bin/curl --fail --silent --show-error --retry 10 --retry-delay 2 --retry-connrefused \
      -X PUT -H "Content-Type: application/json" \
      --data-binary "@$subsFile" \
      "http://${cfg.backendHost}:${toString cfg.backendPort}$SUB_STORE_FRONTEND_BACKEND_PATH/api/subs"
    ${pkgs.curl}/bin/curl --fail --silent --show-error --retry 10 --retry-delay 2 --retry-connrefused \
      -X PUT -H "Content-Type: application/json" \
      --data-binary "@$filesFile" \
      "http://${cfg.backendHost}:${toString cfg.backendPort}$SUB_STORE_FRONTEND_BACKEND_PATH/api/files"
  '';
in
{
  options.services.substore = {
    enable = lib.mkEnableOption "Sub-Store subscription manager with declarative REST API sync";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/sub-store";
      description = "Backend data directory (SUB_STORE_DATA_BASE_PATH).";
    };

    backendHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Backend API host the sync script talks to.";
    };

    backendPort = lib.mkOption {
      type = lib.types.port;
      default = 3001;
      description = "Backend API port the sync script talks to.";
    };

    frontendPath = lib.mkOption {
      type = lib.types.path;
      default = pkgs.sub-store-frontend;
      description = "Path to the Sub-Store frontend build served by the backend.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Extra environment file for the backend unit (e.g. a sops template).";
    };

    payloadPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Directory containing runtime-rendered `subs.json`/`files.json` payloads
        (e.g. outputs of `sops.templates` holding decrypted secret values).
        When set, the sync unit reads the payloads from there instead of the
        build-time store derivations.
      '';
    };

    backendMerge = lib.mkEnableOption ''
      SUB_STORE_BACKEND_MERGE: serve the frontend and API from the single
      backend port. Requires `environmentFile` to provide
      SUB_STORE_FRONTEND_BACKEND_PATH (must start with "/")
    '';

    subscriptions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule subOptions);
      default = { };
      description = "Subscriptions pushed to the backend `subs` array. Attr name is the subscription name.";
    };

    files = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule fileOptions);
      default = { };
      description = "Files/templates pushed to the backend `files` array. Attr name is the file name.";
    };

    renderedSubsJson = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      visible = false;
      description = "Rendered `subs` array as JSON (debug via `nix eval`).";
    };

    renderedFilesJson = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      visible = false;
      description = "Rendered `files` array as JSON (debug via `nix eval`).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      [
        {
          assertion = !(cfg.backendMerge && cfg.environmentFile == null);
          message = "services.substore: backendMerge requires environmentFile to provide SUB_STORE_FRONTEND_BACKEND_PATH";
        }
      ]
      ++ lib.mapAttrsToList (name: _: {
        assertion = !(lib.hasInfix "/" name);
        message = "services.substore.subscriptions: name '${name}' must not contain '/'";
      }) cfg.subscriptions
      ++ lib.mapAttrsToList (name: _: {
        assertion = !(lib.hasInfix "/" name);
        message = "services.substore.files: name '${name}' must not contain '/'";
      }) cfg.files;

    services.substore.renderedSubsJson = subsJson;
    services.substore.renderedFilesJson = filesJson;

    users.users.sub-store = {
      isSystemUser = true;
      group = "sub-store";
    };

    users.groups.sub-store = { };

    systemd.services.sub-store = {
      description = "Sub-Store advanced subscription manager";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.sub-store}/bin/sub-store";
        WorkingDirectory = cfg.dataDir;
        StateDirectory = "sub-store";
        StateDirectoryMode = "0750";
        User = "sub-store";
        Group = "sub-store";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ cfg.dataDir ];
        Environment = [
          "SUB_STORE_FRONTEND_PATH=${cfg.frontendPath}"
          "SUB_STORE_BACKEND_API_PORT=${toString cfg.backendPort}"
          "SUB_STORE_BACKEND_API_HOST=${cfg.backendHost}"
        ]
        ++ (lib.optionals cfg.backendMerge [ "SUB_STORE_BACKEND_MERGE=true" ]);
      }
      // (lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      });
    };

    systemd.services.sub-store-sync = {
      description = "Push declarative Sub-Store configuration via REST API";
      after = [ "sub-store.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [
        subsPayload
        filesPayload
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = syncScript;
        User = "sub-store";
        Group = "sub-store";
        Restart = "on-failure";
        RestartSec = "10s";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      }
      // (lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      });
    };
  };
}

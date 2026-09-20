{
  lib,
  config,
  ...
}:

let
  cfg = config.my.hass;

  containerName = name: "home-assistant-${name}";
  serviceName = name: "podman-${containerName name}.service";

  # An instance's `configDir` is a host directory holding configuration.yaml
  # plus every file configuration.yaml includes (automations.yaml, ...). Each
  # entry of that directory is copied to the store and bind-mounted read-only
  # over /config/<name>, so `!include <name>` resolves while the rest of /config
  # stays the writable runtime directory (`.storage`, recorder DB, logs) it has
  # to be.
  configMounts =
    dir:
    lib.mapAttrsToList (
      name: _: "${builtins.path { inherit name; path = dir + "/${name}"; }}:/config/${name}:ro"
    ) (lib.filterAttrs (_: type: type == "regular" || type == "directory") (builtins.readDir dir));

  mkInstance = name: def: {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    environment = {
      "TZ" = "Asia/Shanghai";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/run/dbus:/run/dbus:ro"
      # Mounted before the config files, which shadow it file by file.
      "${def.dataDir}:/config:rw"
    ] ++ configMounts def.configDir;
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
      "--network=host"
      "--privileged"
    ];
    autoStart = cfg.activeInstance == name;
  };

  otherServices =
    current: lib.map serviceName (lib.attrNames (lib.filterAttrs (n: _: n != current) cfg.instances));
in
{
  options.my.hass = {
    instances = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            configDir = lib.mkOption {
              type = lib.types.path;
              description = ''
                Host directory with this instance's declarative configuration:
                configuration.yaml and every file it includes. All entries are
                mounted read-only into the container, so UI edits of included
                files are rejected and must be made here instead.
              '';
            };
            dataDir = lib.mkOption {
              type = lib.types.path;
              description = "Host directory mounted to /config inside the container.";
            };
          };
        }
      );
      default = { };
      description = "Named Home Assistant instances. Only one (the active instance) runs at a time.";
    };

    activeInstance = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Name of the instance to bring up. Must be one of the keys of
        my.hass.instances, or null if no instance should run. Switching
        is cold: rebuild to the new active instance and systemd Conflicts
        will stop the old one.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.activeInstance == null || cfg.instances ? ${cfg.activeInstance};
        message = "my.hass.activeInstance (`${cfg.activeInstance}`) must be null or a key of my.hass.instances";
      }
    ];

    # Home Assistant uses port 8123 by default
    networking.firewall.allowedTCPPorts = [ 8123 ];
    # Add-on Apple Home Bridge may use these ports by default
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 21063;
        to = 21065;
      }
    ];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 21063;
        to = 21065;
      }
    ];

    # Runtime
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
    };

    virtualisation.oci-containers.backend = "podman";

    systemd.tmpfiles.rules = lib.mapAttrsToList (
      _name: def: "d ${def.dataDir} 0755 root root -"
    ) cfg.instances;

    # Generate one container per declared instance
    virtualisation.oci-containers.containers = lib.mapAttrs' (
      name: def: lib.nameValuePair (containerName name) (mkInstance name def)
    ) cfg.instances;

    # Force every instance service to conflict with all the others so that
    # starting one cold-stops any other that happens to be running.
    systemd.services = lib.mapAttrs' (
      name: _: lib.nameValuePair "podman-${containerName name}" { conflicts = otherServices name; }
    ) cfg.instances;
  };
}

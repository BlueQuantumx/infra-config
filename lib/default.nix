# Host and home constructors shared by flake.nix.
#
# Every system/user configuration is built through these helpers so the common
# module set, the shared source of truth (`defaults.nix`) and `specialArgs` are
# declared exactly once. Per-host files only declare deltas.
{ nixpkgs, inputs }:
let
  lib = nixpkgs.lib;
  defaults = import ../defaults.nix;

  baseSpecialArgs = {
    inherit inputs defaults;
  };
in
rec {
  inherit defaults baseSpecialArgs;

  # NixOS host. `disko` is always applied; home-manager/sops are opt-in so hosts
  # that do not use them keep their exact configuration.
  mkNixos =
    {
      hostName,
      modules,
      system ? null,
      homeManager ? false,
      sops ? false,
      nixosSystem ? nixpkgs.lib.nixosSystem,
      systemArgs ? { },
      extraSpecialArgs ? { },
    }:
    nixosSystem (
      systemArgs
      // lib.optionalAttrs (system != null) { inherit system; }
      // {
        specialArgs = baseSpecialArgs // { inherit hostName; } // extraSpecialArgs;
        modules =
          [ inputs.disko.nixosModules.disko ]
          ++ lib.optional homeManager inputs.home-manager.nixosModules.home-manager
          ++ lib.optional sops inputs.sops-nix.nixosModules.sops
          ++ lib.optional homeManager {
            # The integrated home-manager reuses the system nixpkgs (overlays are
            # applied once, in modules/overlays.nix), and receives the shared args.
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = baseSpecialArgs;
          }
          ++ modules;
      }
    );

  # nix-darwin host.
  mkDarwin =
    {
      hostName,
      modules,
      extraSpecialArgs ? { },
    }:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = baseSpecialArgs // { inherit hostName; } // extraSpecialArgs;
      modules = modules;
    };

  # Standalone home-manager configuration (macOS / unmanaged hosts).
  mkHome =
    {
      system,
      modules,
      extraSpecialArgs ? { },
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = baseSpecialArgs // extraSpecialArgs;
      modules = modules;
    };

  # Shared module sets, exported by the flake so hosts import via
  # `inputs.self.nixosModules.<name>` instead of depth-dependent relative paths.
  nixosModules = {
    base = ../hosts/modules/base.nix;
    server = ../hosts/modules/server.nix;
    cloud-vm = ../hosts/modules/cloud-vm.nix;
    overlays = ../hosts/modules/overlays.nix;
    sops = ../hosts/modules/sops-common.nix;
    prelude = ../hosts/modules/prelude.nix;
    prelude-linux = ../hosts/modules/prelude-linux.nix;
    vsc-remote-workaround = ../hosts/modules/vsc-remote-workaround.nix;
    azure = ../hosts/modules/azure.nix;
    my-et-network = ../hosts/modules/my-et-network.nix;
    substore = ../hosts/modules/sub-store.nix;
    sing-box = ../hosts/modules/sing-box.nix;
    home-assistant = ../hosts/modules/home-assistant.nix;
    wifi = ../hosts/modules/wifi.nix;
    hust-network-login = ../hosts/modules/hust-network-login.nix;
  };

  homeManagerModules = {
    base = ../home-manager/modules/base.nix;
    direnv = ../home-manager/modules/direnv.nix;
    ghostty = ../home-manager/modules/ghostty.nix;
    git = ../home-manager/modules/git.nix;
    github-token = ../home-manager/modules/github-token.nix;
    xcode = ../home-manager/modules/xcode.nix;
    zsh = ../home-manager/modules/zsh.nix;
  };

  darwinModules = {
    homebrew = ../hosts/modules/homebrew.nix;
  };
}

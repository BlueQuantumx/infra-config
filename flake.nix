{
  description = "Personal Nix flake: NixOS, nix-darwin and home-manager hosts";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # Unstable nixpkgs, exposed as pkgs.unstable for overlaid packages that
    # need to move faster than the stable channel.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS Raspberry Pi configurations and installer images
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    # Sops-nix, for secrets management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # nix-darwin, for macOS system configuration
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # nix-homebrew, for declarative Homebrew on macOS
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      nixos-raspberrypi,
      sops-nix,
      nix-darwin,
      ...
    }@inputs:
    let
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Host/home constructors and shared module sets (see lib/default.nix).
      helper = import ./lib { inherit nixpkgs inputs; };
      inherit (helper) defaults;

      # Single source of truth shared between the NixOS configuration and the
      # OpenTofu infrastructure (see defaults.nix)
      infraDefaults = defaults;

      # Values injected into tofu/terraform.tfvars.json by the
      # tofu-* apps below; OpenTofu auto-loads that file
      tofuVars = {
        location = infraDefaults.azure.location;
        name_prefix = infraDefaults.azure.namePrefix;
        vm_size = infraDefaults.azure.vmSize;
        admin_username = infraDefaults.azure.adminUsername;
        ssh_public_key_file = infraDefaults.azure.sshPublicKeyFile;
        ssh_private_key_file = infraDefaults.azure.sshPrivateKeyFile;
        domain_personal = infraDefaults.domain;
        entra_custom_domain = infraDefaults.entra.customDomain;
        subdomain_substore = infraDefaults.subdomains.substore;
        subdomain_azure = infraDefaults.subdomains.azure;
        subdomain_navidrome = infraDefaults.subdomains.navidrome;
        enable_easytier = infraDefaults.easytier.enable;
        easy_tier_tcp_ports = infraDefaults.easytier.tcpPorts;
        easy_tier_udp_ports = infraDefaults.easytier.udpPorts;
        public_ip_revision = infraDefaults.azure.publicIpRevision;
      };

      tofuApp =
        command: system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tofuDir = "tofu";
          writeVars = pkgs.writeShellScript "write-tofu-vars" ''
            set -euo pipefail
            echo ${nixpkgs.lib.escapeShellArg (builtins.toJSON tofuVars)} > "$(git rev-parse --show-toplevel)/${tofuDir}/terraform.tfvars.json"
          '';
        in
        {
          type = "app";
          program = toString (
            pkgs.writeShellScript "tofu-${command}" ''
              set -euo pipefail
              ${writeVars}
              cd "$(git rev-parse --show-toplevel)/${tofuDir}"
              exec ${pkgs.opentofu}/bin/tofu ${command} "$@"
            ''
          );
        };

      tofuVarsApp =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          type = "app";
          program = toString (
            pkgs.writeShellScript "tofu-vars" ''
              set -euo pipefail
              echo ${nixpkgs.lib.escapeShellArg (builtins.toJSON tofuVars)} > "$(git rev-parse --show-toplevel)/tofu/terraform.tfvars.json"
              echo "wrote tofu/terraform.tfvars.json"
            ''
          );
        };

      # Runs `tofu` inside the isolated tailnet stack (tofu/tailnet), which has
      # its own state key and needs no generated variables.
      tailnetApp =
        command: system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          type = "app";
          program = toString (
            pkgs.writeShellScript "tofu-tailnet-${command}" ''
              set -euo pipefail
              cd "$(git rev-parse --show-toplevel)/tofu/tailnet"
              exec ${pkgs.opentofu}/bin/tofu ${command} "$@"
            ''
          );
        };

      # Bridges the tailnet stack's sensitive auth-key outputs into the
      # sops-encrypted secrets file. Terraform cannot write sops, so this is the
      # one manual re-run step after `tofu-tailnet-apply`.
      tofuTailnetSecretsApp =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          type = "app";
          program = toString (
            pkgs.writeShellScript "tofu-tailnet-secrets" ''
              set -euo pipefail
              root="$(git rev-parse --show-toplevel)"
              keys="$(mktemp)"
              chmod 600 "$keys"
              trap 'rm -f "$keys"' EXIT
              ${pkgs.opentofu}/bin/tofu -chdir="$root/tofu/tailnet" output -json > "$keys"
              # Each minted key is written to the secrets file scoped to its
              # consumer: raspi reads its own node key, azure consumes the rest
              # (its own node key plus the mobile/desktop profile keys).
              for node in azure raspi mac ios linux_desktop; do
                case "$node" in
                  raspi) target="$root/secrets/raspi.yaml" ;;
                  *) target="$root/secrets/azure.yaml" ;;
                esac
                value="$(${pkgs.jq}/bin/jq -r --arg n "authkey_$node" '.[$n].value' "$keys")"
                json="$(${pkgs.jq}/bin/jq -Rn --arg v "$value" '$v')"
                ${pkgs.sops}/bin/sops set "$target" "[\"tailscale\"][\"authkey_$node\"]" "$json"
              done
              echo "wrote tailscale auth keys into host-scoped secrets files"
            ''
          );
        };

      # One check per host so `nix flake check` fails when a host stops
      # evaluating. Use `--no-build` for a fast evaluation-only pass.
      hostChecks = {
        x86_64-linux = {
          azure = self.nixosConfigurations.azure.config.system.build.toplevel;
          pascal-cloud-01 = self.nixosConfigurations.pascal-cloud-01.config.system.build.toplevel;
          digitalocean = self.nixosConfigurations.digitalocean.config.system.build.toplevel;
          "529-2" = self.nixosConfigurations."529-2".config.system.build.toplevel;
        };
        aarch64-linux = {
          raspi = self.nixosConfigurations.raspi.config.system.build.toplevel;
          orbstack = self.nixosConfigurations.orbstack.config.system.build.toplevel;
        };
        aarch64-darwin = {
          macbook = self.darwinConfigurations."Louis-MacBook-Pro-2024".system;
        };
      };
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = false;
          };
        in
        {
          default = pkgs.mkShellNoCC {
            name = "nix-config-dev";
            nativeBuildInputs = with pkgs; [
              nixd # lsp language server for nix
              nixpkgs-fmt
              nixfmt
              nix-output-monitor
              bash-language-server
              shellcheck
              gh
              sops
              nixos-anywhere
              nixos-generators
              nixos-rebuild
              azure-cli
              opentofu
            ];
          };
        }
      );
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        nixpkgs.lib.filterAttrs (_: pkg: pkgs.lib.meta.availableOn { inherit system; } pkg) (
          import ./pkgs pkgs
        )
      );

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Shared values for the tofu/ infrastructure
      # Check with: nix eval .#tofuVars --json
      inherit tofuVars;

      # OpenTofu helpers for tofu/. Regenerate terraform.tfvars.json
      # from Nix and run tofu, e.g. `nix run .#tofu-plan`
      apps = forAllSystems (system: {
        tofu-vars = tofuVarsApp system;
        tofu-plan = tofuApp "plan" system;
        tofu-apply = tofuApp "apply" system;
        tofu-tailnet-plan = tailnetApp "plan" system;
        tofu-tailnet-apply = tailnetApp "apply" system;
        tofu-tailnet-secrets = tofuTailnetSecretsApp system;
      });

      # Reusable modules and constructors.
      inherit (helper) nixosModules homeManagerModules darwinModules;
      lib = {
        inherit (helper) mkNixos mkDarwin mkHome;
        inherit defaults;
      };

      # Installer images
      installerImages =
        let
          installerImages = nixos-raspberrypi.installerImages;
        in
        {
          rpi4 = installerImages.rpi4;
        };

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        raspi = helper.mkNixos {
          hostName = "raspi";
          nixosSystem = nixos-raspberrypi.lib.nixosSystem;
          systemArgs = { inherit nixpkgs; };
          homeManager = true;
          sops = true;
          modules = [ ./hosts/raspi/configuration.nix ];
        };

        digitalocean = helper.mkNixos {
          hostName = "digitalocean";
          system = "x86_64-linux";
          modules = [
            { disko.devices.disk.disk1.device = "/dev/vda"; }
            ./hosts/digital-ocean/configuration.nix
          ];
        };

        azure = helper.mkNixos {
          hostName = "azure";
          system = "x86_64-linux";
          homeManager = true;
          sops = true;
          modules = [ ./hosts/azure/configuration.nix ];
        };

        pascal-cloud-01 = helper.mkNixos {
          hostName = "pascal-cloud-01";
          system = "x86_64-linux";
          homeManager = true;
          sops = true;
          modules = [ ./hosts/pascal-cloud-01/configuration.nix ];
        };

        orbstack = helper.mkNixos {
          hostName = "orbstack";
          system = "aarch64-linux";
          homeManager = true;
          modules = [ ./hosts/orb/configuration.nix ];
        };

        # Physical x86_64 desktop, managed from the installer-generated
        # hardware-configuration.nix (no disko).
        "529-2" = helper.mkNixos {
          hostName = "529-2";
          system = "x86_64-linux";
          sops = true;
          modules = [ ./hosts/529-2/configuration.nix ];
        };
      };

      # nix-darwin configuration entrypoint
      # Available through 'darwin-rebuild --flake .#Louis-MacBook-Pro-2024'
      darwinConfigurations."Louis-MacBook-Pro-2024" = helper.mkDarwin {
        hostName = "macbook";
        modules = [
          ./hosts/macbook/configuration.nix
        ];
      };

      # Standalone home-manager configuration entrypoint (MacBook/macOS only;
      # NixOS hosts use home-manager integrated as a NixOS module)
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        "luyan@macbook" = helper.mkHome {
          system = "aarch64-darwin";
          modules = [
            ./home-manager/luyan-macbook.nix
          ];
        };

        "zly@pascal06" = helper.mkHome {
          system = "x86_64-linux";
          modules = [
            ./home-manager/luyan-pascal06.nix
          ];
        };
      };

      checks = hostChecks;
    };
}

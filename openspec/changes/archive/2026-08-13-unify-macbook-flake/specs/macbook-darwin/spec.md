## ADDED Requirements

### Requirement: MacBook nix-darwin configuration managed from root flake

The root `flake.nix` SHALL expose the MacBook's nix-darwin system configuration as `darwinConfigurations."Louis-MacBook-Pro-2024"`, built with the `nix-darwin` input and the root's `nixos-26.05` nixpkgs branch.

#### Scenario: Build the MacBook darwin configuration from the repo root

- **WHEN** a user runs `darwin-rebuild build --flake .#Louis-MacBook-Pro-2024` from the repo root
- **THEN** the darwin configuration evaluates successfully using `nixos-26.05` nixpkgs

### Requirement: nix-darwin and nix-homebrew inputs on root flake

The root `flake.nix` SHALL declare `nix-darwin` and `nix-homebrew` inputs, where `nix-darwin.inputs.nixpkgs.follows` the root `nixpkgs` input.

#### Scenario: Inputs are present in the root lock file

- **WHEN** the root `flake.lock` is refreshed
- **THEN** it records both the `nix-darwin` and `nix-homebrew` input sources

### Requirement: Single home-manager definition for the MacBook

The repository SHALL define `homeConfigurations."luyan@macbook"` exactly once, in the root `flake.nix`.

#### Scenario: No duplicate home config after removing the sub-flake

- **WHEN** a user searches the repo for `luyan@macbook`
- **THEN** only the root `flake.nix` defines the `luyan@macbook` home-manager configuration

### Requirement: MacBook configuration located under hosts/macbook

The MacBook's darwin system configuration SHALL live at `hosts/macbook/configuration.nix`, following the same per-host layout as other hosts.

#### Scenario: Sub-flake removed

- **WHEN** the change is complete
- **THEN** `hosts/macbook/flake.nix` and `hosts/macbook/flake.lock` no longer exist, and `hosts/macbook/configuration.nix` exists

### Requirement: Other hosts unchanged

This change SHALL NOT alter the configuration of raspi, digitalocean, or azure, nor their home-manager configs, secrets, or OpenTofu infrastructure.

#### Scenario: Unaffected hosts still build

- **WHEN** `nix flake check` runs after the change
- **THEN** the NixOS and home-manager configurations for raspi, digitalocean, and azure remain unchanged

### Requirement: OrbStack resolvconf assertion fixed

The orbstack NixOS configuration SHALL set `networking.resolvconf.enable = false` so that the OrbStack-managed `environment.etc."resolv.conf"` does not trigger the resolvconf assertion.

#### Scenario: OrbStack configuration evaluates without assertion failure

- **WHEN** `nix flake check` evaluates `nixosConfigurations.orbstack`
- **THEN** no `networking.resolvconf` vs `environment.etc."resolv.conf"` assertion failure occurs

### Requirement: Custom packages exposed only on supported platforms

The root flake's `packages` output SHALL expose each custom package only on systems where the package's `meta.platforms` allows it.

#### Scenario: Linux-only package not exposed on darwin

- **WHEN** a package declares `meta.platforms = [ "aarch64-linux" ]`
- **THEN** `packages.aarch64-darwin` does not include that package, and `nix flake check` does not attempt to build it on darwin


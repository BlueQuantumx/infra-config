## Purpose

Defines the structural contract of the flake: a single source of truth for shared values, reusable exported modules, uniform host construction, and reproducible checks — so hosts and home profiles declare only their deltas and cannot drift from each other.

## ADDED Requirements

### Requirement: Single source of truth for shared values

The flake SHALL resolve shared infrastructure and identity values (user identity and home directories, SSH public keys, domain and subdomains, per-host hostnames/roles, and infrastructure parameters consumed by OpenTofu) from one root `defaults.nix`. Host and home-manager configurations SHALL reference those values rather than redeclaring them.

#### Scenario: No duplicated literal

- **WHEN** a value such as a username, SSH key, hostname, or domain is used on multiple hosts or by OpenTofu
- **THEN** it is declared once in `defaults.nix` and referenced everywhere else

#### Scenario: OpenTofu var generation stays consistent

- **WHEN** the flake regenerates OpenTofu variables (`terraform.tfvars.json`)
- **THEN** the values come from the same `defaults.nix` used by the NixOS configurations, with no separate copy

#### Scenario: Per-host admin access derives from the registry

- **WHEN** a host's admin SSH keys are declared
- **THEN** the same list provisions both the admin user and root, with no repetition within the host file

### Requirement: Reusable modules are exported by the flake

The flake SHALL expose the shared NixOS, home-manager, and darwin modules as flake outputs (`nixosModules`, `homeManagerModules`, `darwinModules`), and host and home configurations SHALL import shared logic through those outputs rather than environment-specific relative paths. Shared module files SHALL remain under `hosts/modules/` and `home-manager/modules/`.

#### Scenario: Shared module usable as a flake output

- **WHEN** a host imports a shared module
- **THEN** it can do so via a flake module output without depending on the importing file's directory depth

#### Scenario: Module locations preserved

- **WHEN** the refactor is complete
- **THEN** shared host modules still live under `hosts/modules/` and shared user modules under `home-manager/modules/`

### Requirement: Uniform host construction

Every NixOS and darwin host SHALL be constructed through a shared constructor in the flake that applies the common module set (disko, home-manager integration, sops-nix) and passes the shared `specialArgs` consistently. Per-host files SHALL declare only host-specific deltas.

#### Scenario: Consistent special arguments

- **WHEN** any host is evaluated
- **THEN** it receives the same shared arguments (flake inputs and defaults), with no host omitted

#### Scenario: Consistent module set

- **WHEN** a host that integrates home-manager or disko is evaluated
- **THEN** the common integration modules are applied by the constructor rather than repeated in the host file

### Requirement: Overlays are applied once per nixpkgs instance

Nixpkgs overlays and configuration SHALL be declared once per nixpkgs instance. For integrated home-manager, the user configuration SHALL reuse the system nixpkgs rather than constructing a separate instance, so a package name resolves identically for the system and the user.

#### Scenario: Shared package resolution

- **WHEN** an integrated home-manager profile references a package also present in the system profile
- **THEN** both resolve to the same nixpkgs instance and overlay results

#### Scenario: Standalone profiles keep their own nixpkgs

- **WHEN** a standalone `homeConfigurations` profile (not integrated into a system) is evaluated
- **THEN** it still declares the overlays it needs, since it does not inherit a system nixpkgs

### Requirement: Flake checks evaluate every declared host

The flake SHALL provide `checks` that evaluate every declared NixOS and darwin host, so `nix flake check` fails when a host configuration no longer evaluates.

#### Scenario: Broken host fails the check

- **WHEN** a host configuration has an evaluation error
- **THEN** `nix flake check` reports failure for that host

#### Scenario: Healthy flake passes

- **WHEN** all hosts evaluate
- **THEN** `nix flake check` succeeds

### Requirement: Deployed behavior is preserved

The refactor SHALL NOT change the observable configuration of any deployed host. SSH hardening, admin user and group membership, disk layout, secret wiring, and enabled services SHALL remain equivalent before and after.

#### Scenario: Host config equivalence

- **WHEN** a host's evaluated configuration is compared before and after the refactor
- **THEN** no behavioral difference is introduced beyond the intended structural changes

#### Scenario: Standalone home profiles retained

- **WHEN** the macOS and remote standalone home profiles are evaluated
- **THEN** they remain available as `homeConfigurations` outputs

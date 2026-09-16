## Why

The flake has grown by accretion: host configs and home-manager files repeat the same ssh/user/overlay/stateVersion boilerplate, semantically-equal values (username, SSH keys, hostnames, overlays, domain) are declared in many places, and the structure deviates from common practice (no exported modules, no `checks`, duplicated per-host module lists, integrated home-manager builds its own nixpkgs). Adding a host is expensive and drift-prone.

## What Changes

- Introduce a root `defaults.nix` as the single source of truth (identity/users, SSH keys, domain/subdomains, azure/easytier infra, host registry), consumed by Nix and by OpenTofu var generation.
- Add shared `hosts/modules/base.nix`, `server.nix`, `cloud-vm.nix`, `overlays.nix`, `sops-common.nix` and `home-manager/modules/base.nix`; collapse near-identical host and home-manager files onto them.
- Export `nixosModules`, `homeManagerModules`, `darwinModules`, and `lib` from the flake; add `checks`.
- Add host constructors in `lib/` (`mkNixos` / `mkHome`) so disko/home-manager/sops wiring and `specialArgs` are declared once.
- Set `home-manager.useGlobalPkgs = true`; apply nixpkgs overlays once at system level.
- Keep `hosts/modules` and `home-manager/modules` at their current paths; hosts import shared modules via flake outputs.
- Preserve the standalone `homeConfigurations` for macbook and pascal06.
- Remove template leftovers and the dead `hosts/modules/default.nix`; fold the duplicated sops environment workaround into a shared module.

No change to deployed system behavior is intended.

## Capabilities

### New Capabilities

- `flake-structure`: contract for flake outputs, exported modules, the single source of truth, host constructors, and checks.

### Modified Capabilities

- (none)

## Impact

- Hosts affected: all — azure, pascal-cloud-01, raspi, digital-ocean, orbstack, macbook — plus all home-manager configurations.
- Secrets: no new secrets; sops files, recipients, and secret paths are unchanged.
- OpenTofu: `tofu/defaults.nix` relocates to repo root; the flake `tofuVars` mapping is updated. No HCL or state change.
- Verification: `nix flake check` plus a dry-build per host before/after.

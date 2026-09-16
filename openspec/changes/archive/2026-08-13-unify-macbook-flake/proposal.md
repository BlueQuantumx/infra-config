## Why

The MacBook is the only host still living in its own sub-flake (`hosts/macbook/flake.nix`), while every other host (raspi / digitalocean / azure / orbstack) is managed from the root `flake.nix`. This creates drift: `homeConfigurations."luyan@macbook"` is defined twice (root flake and sub-flake) against two different nixpkgs branches (`nixos-26.05` vs `nixpkgs-26.05-darwin`), and rebuilding the laptop requires `cd hosts/macbook` instead of staying at the repo root.

## What Changes

- Add `nix-darwin` and `nix-homebrew` as inputs to the root `flake.nix`.
- Standardize the MacBook nixpkgs on `nixos-26.05` (same branch as all other hosts).
- Move the nix-darwin configuration into `hosts/macbook/configuration.nix` and expose it as `darwinConfigurations."Louis-MacBook-Pro-2024"` from the root flake.
- Keep the existing `homeConfigurations."luyan@macbook"` in the root flake as the single definition.
- Remove `hosts/macbook/flake.nix` and `hosts/macbook/flake.lock`.
- Filter the root `packages` output by `meta.platforms`, so linux-only packages (e.g. `hust-network-login`) are not exposed on `aarch64-darwin` and `nix flake check` passes.
- Set `networking.resolvconf.enable = false` in `hosts/orb/configuration.nix` to fix a pre-existing assertion failure blocking `nix flake check`.
- **No other hosts, home-manager configs, secrets, or OpenTofu infra are changed.**

## Capabilities

### New Capabilities

- `macbook-darwin`: Management of the MacBook's nix-darwin system configuration (and its homebrew integration) from the root flake.

### Modified Capabilities

<!-- None. Existing specs (e.g. tofu-infra) are unaffected. -->

## Impact

- `flake.nix` (root): new inputs, `darwinConfigurations` output, filtered `packages` output.
- `hosts/macbook/`: `configuration.nix` added; `flake.nix` / `flake.lock` removed.
- `hosts/orb/configuration.nix`: `networking.resolvconf.enable = false`.
- `flake.lock` (root): refreshed to include nix-darwin and nix-homebrew.
- Affected hosts: macbook, orbstack. No secrets or OpenTofu state involved.

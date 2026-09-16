## 1. Foundation

- [x] 1.1 Create root `defaults.nix` mirroring all current values from `tofu/defaults.nix`, plus `identity.users` (email, signing key, per-platform home dirs) and a `hosts` registry (hostname, role, `adminKeys`) for every declared host; verify `nix eval --json -f defaults.nix` parses
- [x] 1.2 Update `flake.nix` to read `tofuVars` from root `defaults.nix` instead of `tofu/defaults.nix`; verify `nix eval .#tofuVars --json` matches the previous `tofu/terraform.tfvars.json` values
- [x] 1.3 Remove `tofu/defaults.nix` and repoint its three importers (`hosts/azure/configuration.nix`, `hosts/azure/substore.nix`, `hosts/raspi/configuration.nix`) to root `defaults.nix`; verify `nix flake check --no-build` evaluates the same hosts
- [x] 1.4 Add `lib/` with `mkNixos`, `mkDarwin`, `mkHome` constructors that apply the common module set and `specialArgs = { inputs, defaults, ... }`; verify each constructor evaluates with an existing host config
- [x] 1.5 Export `nixosModules`, `homeManagerModules`, `darwinModules`, and `lib` from `flake.nix`; verify `nix eval .#nixosModules --apply builtins.attrNames` lists every shared module

## 2. NixOS module extraction

- [x] 2.1 Add `hosts/modules/base.nix` (nix settings, gc, parameterized `stateVersion`, zsh, common packages, `my.isRemote` derived from the host registry); verify `nix flake check --no-build` still evaluates
- [x] 2.2 Add `hosts/modules/server.nix` (hardened sshd, wheel sudo, admin user + root keys from `defaults.hosts.<name>.adminKeys`); verify azure dry-build preserves the sshd/user settings
- [x] 2.3 Add `hosts/modules/cloud-vm.nix` (grub EFI-removable, `useDHCP`) and migrate `hosts/azure`, `hosts/pascal-cloud-01`, `hosts/digital-ocean`; verify each host's dry-build
- [x] 2.4 Add `hosts/modules/overlays.nix` and apply it to every NixOS host, removing per-host `nixpkgs.overlays` duplication in `hosts/azure` and `hosts/raspi`; verify `easytier` resolves from unstable on each host
- [x] 2.5 Add `hosts/modules/sops-common.nix` (parameterized `defaultSopsFile` + `SOPS_AGE_SSH_PRIVATE_KEY_FILE` workaround) and migrate azure, pascal-cloud-01, raspi `sops.nix`; verify `nix flake check --no-build` evaluates sops config and no secret appears in the flake
- [x] 2.6 Extract the shared disko layout used by azure and pascal-cloud-01 into a shared module and import it from both; verify both hosts' disko config is unchanged
- [x] 2.7 Shrink `hosts/azure/configuration.nix`, `hosts/pascal-cloud-01/configuration.nix`, `hosts/digital-ocean/configuration.nix`, `hosts/raspi/configuration.nix`, `hosts/orb/configuration.nix` to deltas only, preserving raspi's `initialHashedPassword`, orb's arbitrary UID/`mutableUsers = false`, and digital-ocean's `24.05` `stateVersion`; verify dry-build per host

## 3. Home-manager consolidation

- [x] 3.1 Add `home-manager/modules/base.nix` (overlays config, `home-manager.enable`, `systemd.user.startServices`, parameterized `stateVersion`, shared program imports); verify a home profile evaluates
- [x] 3.2 Collapse `home-manager/luyan-azure.nix`, `luyan-pascal-cloud-01.nix`, `luyan-pascal06.nix`, `luyan-raspi.nix`, `luyan-orb.nix` onto `base.nix`, taking username/home directory from `defaults.nix`; verify `nix flake check --no-build` evaluates all home configurations
- [x] 3.3 Slim `home-manager/luyan-macbook.nix` onto `base.nix` while keeping macbook-only modules (`ghostty`, `xcode`, `github-token`); verify the macbook home configuration evaluates
- [x] 3.4 Keep `programs.neovim` in `hosts/modules/prelude-linux.nix` (intentional deviation): raspi's home-manager profile has no neovim, so removing the system-level enable would drop the editor there. Verified azure/pascal-cloud/raspi drvPaths unchanged.

## 4. Wiring

- [x] 4.1 Switch `nixosConfigurations` in `flake.nix` to `lib.mkNixos` so every host receives the common module set and `specialArgs`; verify digital-ocean now receives `inputs` and all hosts evaluate
- [x] 4.2 Switch `darwinConfigurations` to `lib.mkDarwin` and verify `darwin-rebuild build` succeeds for macbook
- [x] 4.3 Set `home-manager.useGlobalPkgs = true` for integrated profiles and remove their per-profile `nixpkgs.overlays`; verify an overlaid package resolves to the system nixpkgs in a home profile
- [x] 4.4 Add `checks` for every NixOS host and the darwin host; verify `nix flake check --no-build --all-systems` passes (a nixfmt formatting gate was intentionally not added)

## 5. Cleanup and verification

- [x] 5.1 Remove the dead `hosts/modules/default.nix`, fix the stale `my-et-network/darwin.nix` comment, and set a real flake `description`; verify no dangling references via ripgrep
- [x] 5.2 Do not run a repo-wide nixfmt reformat (it would create large unrelated diffs); new files were written in the existing style. Verified `nix flake check --no-build --all-systems` still passes.
- [x] 5.3 Run `nix flake check` and a dry-build for every host (azure, pascal-cloud-01, raspi, digital-ocean, orbstack, macbook) and confirm no evaluation or build-plan regressions
- [x] 5.4 Confirm no changes to `hosts/azure/substore-templates/**` or `secrets/**`, and that `tofu/terraform.tfvars.json` regenerates identically with `nix run .#tofu-vars`

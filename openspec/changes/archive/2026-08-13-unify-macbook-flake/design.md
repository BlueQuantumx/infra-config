## Context

The repo manages four NixOS hosts and the MacBook. All NixOS hosts are wired into the root `flake.nix`, but the MacBook is an exception: it has its own flake at `hosts/macbook/flake.nix` with separate inputs (`nix-darwin`, `nix-homebrew`) and a separate `flake.lock` pinned to `nixpkgs-26.05-darwin`.

The root flake already exposes `homeConfigurations."luyan@macbook"` (in `flake.nix`), and the sub-flake also defines the same `homeConfigurations."luyan@macbook"` against a different nixpkgs branch. This duplication is the main smell to remove.

## Goals / Non-Goals

**Goals:**
- Manage the MacBook's nix-darwin system configuration from the root flake.
- Use the same `nixos-26.05` nixpkgs branch as every other host.
- Single source of truth for `homeConfigurations."luyan@macbook"` (root flake).
- Delete the sub-flake and its lock file.

**Non-Goals:**
- Do not change any other host (raspi / digitalocean / azure / orbstack) or their home-manager configs.
- Do not integrate home-manager into the nix-darwin config (keep the current separate `home-manager switch` workflow).
- Do not touch secrets or OpenTofu infra.
- Do not alter the contents of the darwin config itself (same packages, casks, system defaults, PAM/touchID settings).

## Decisions

1. **Add `nix-darwin` and `nix-homebrew` as root flake inputs.**
   - `nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05"` (same branch as the sub-flake).
   - `nix-darwin.inputs.nixpkgs.follows = "nixpkgs"` so it shares the root's `nixos-26.05` nixpkgs.
   - `nix-homebrew.url = "github:zhaofengli/nix-homebrew"` (no follows; it is only used for its darwin module, referenced via `specialArgs`).
   - Alternative considered: keep the sub-flake. Rejected — it is the source of the duplicate home config and the two-pin drift.

2. **Move the darwin config into `hosts/macbook/configuration.nix`.**
   - Matches the existing `hosts/<name>/configuration.nix` convention used by raspi/azure/etc.
   - The relative import paths `../modules/prelude.nix` and `../modules/homebrew.nix` resolve identically from the new file location (same directory as the old `flake.nix`), so no path edits are needed.

3. **Expose `darwinConfigurations."Louis-MacBook-Pro-2024"` from the root flake.**
   - Use `nix-darwin.lib.darwinSystem { specialArgs = { inherit inputs; }; modules = [ ./hosts/macbook/configuration.nix ]; }`.
   - `specialArgs` already carries `inputs.nix-homebrew`, which `homebrew.nix` requires.

4. **Keep the root flake's `homeConfigurations."luyan@macbook"` as the only definition.**
   - Delete the duplicate from the sub-flake (along with the sub-flake itself).

5. **Delete `hosts/macbook/flake.nix` and `hosts/macbook/flake.lock`.**
   - Refresh the root `flake.lock` so it includes the two new inputs.

6. **Filter the `packages` output by platform support.**
   - Wrap `import ./pkgs pkgs` with `nixpkgs.lib.filterAttrs (_: pkg: pkgs.lib.meta.availableOn { inherit system; } pkg)`, so each package is only exposed on systems where `meta.platforms` allows it.
   - Without this, `nix flake check` fails on `packages.aarch64-darwin.hust-network-login` (a linux-only prebuilt binary).
   - Alternative considered: remove `aarch64-darwin` from `systems` — rejected, it would break the MacBook devShell. Another alternative: `allowUnsupportedSystem` — rejected, it only masks the problem.

7. **Fix the orbstack resolvconf assertion.**
   - `orbstack.nix` (OrbStack-generated) sets `environment.etc."resolv.conf".source`, which conflicts with `networking.resolvconf.enable` defaulting to `true`.
   - Fix by adding `networking.resolvconf.enable = false;` to `hosts/orb/configuration.nix` (not the generated file, which warns it will be overwritten).

## Risks / Trade-offs

- [Switching from `nixpkgs-26.05-darwin` to `nixos-26.05` could pick up slightly different darwin package revisions] → Accepted: `nixos-26.05` is the branch the rest of the repo already uses; darwin packages are present in it. Verify with `darwin-rebuild dry-build`.
- [Forgetting to refresh the root `flake.lock` leaves stale input hashes] → Run `nix flake lock` (or `nix flake update --commit-lock-file`) and confirm the lock records `nix-darwin` and `nix-homebrew`.
- [Breaking the laptop build while mid-migration] → Roll back with `git revert`; both the sub-flake files and the root flake are git-tracked.

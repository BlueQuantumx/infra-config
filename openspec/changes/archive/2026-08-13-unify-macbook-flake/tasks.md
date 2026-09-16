## 1. Add darwin inputs to the root flake

- [x] 1.1 Add `nix-darwin` input to `flake.nix` (`nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05"` with `nixpkgs.follows = "nixpkgs"`)
- [x] 1.2 Add `nix-homebrew` input to `flake.nix` (`github:zhaofengli/nix-homebrew`)
- [x] 1.3 Refresh `flake.lock` (`nix flake lock`) so both new inputs are recorded

## 2. Move the darwin configuration

- [x] 2.1 Create `hosts/macbook/configuration.nix` from the inline config in `hosts/macbook/flake.nix` (imports `../modules/prelude.nix` and `../modules/homebrew.nix`, plus packages/casks/defaults/PAM unchanged)
- [x] 2.2 Add `darwinConfigurations."Louis-MacBook-Pro-2024"` to the root `flake.nix` outputs using `nix-darwin.lib.darwinSystem { specialArgs = { inherit inputs; }; modules = [ ./hosts/macbook/configuration.nix ]; }`

## 3. Remove the sub-flake

- [x] 3.1 Delete `hosts/macbook/flake.nix`
- [x] 3.2 Delete `hosts/macbook/flake.lock`
- [x] 3.3 Confirm `homeConfigurations."luyan@macbook"` remains defined only in the root `flake.nix`

## 4. Filter packages by platform

- [x] 4.1 Filter the root `packages` output with `pkgs.lib.meta.availableOn { inherit system; }` so linux-only packages (e.g. `hust-network-login`) are not exposed on `aarch64-darwin`

## 5. Fix orbstack resolvconf assertion

- [x] 5.1 Set `networking.resolvconf.enable = false` in `hosts/orb/configuration.nix` so it does not conflict with `environment.etc."resolv.conf"` from `orbstack.nix`

## 6. Verify

- [x] 6.1 Run `nix flake check` — passes
- [x] 6.2 Run `darwin-rebuild build --flake .#Louis-MacBook-Pro-2024`
- [x] 6.3 Run `home-manager build --flake .#luyan@macbook`

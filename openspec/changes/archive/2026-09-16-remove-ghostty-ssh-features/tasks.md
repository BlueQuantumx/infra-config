## 1. Remove the SSH shell-integration setting

- [x] 1.1 Delete the `shell-integration-features = "ssh-env,ssh-terminfo";` line from `home-manager/modules/ghostty.nix`, then verify with `grep -n "ssh-env\|ssh-terminfo" home-manager/modules/ghostty.nix` that no SSH shell-integration entry remains.
- [x] 1.2 Confirm no other Ghostty setting was touched by reviewing `git diff home-manager/modules/ghostty.nix` (only the one line removed).

## 2. Verify the MacBook configuration

- [x] 2.1 Evaluate the flake with `nix flake check` (or `darwin-rebuild build --flake .#Louis-MacBook-Pro-2024`) and verify it succeeds.
- [x] 2.2 Build the MacBook home config (`home-manager build --flake .#luyan@macbook`) and verify the generated Ghostty config contains no enabled `ssh-env` / `ssh-terminfo` shell-integration feature.

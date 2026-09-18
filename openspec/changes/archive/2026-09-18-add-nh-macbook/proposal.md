## Why

The MacBook drives its two configurations with `darwin-rebuild --flake .#Louis-MacBook-Pro-2024` and `home-manager switch --flake .#luyan@macbook`, which requires remembering the flake path and target from any directory. `nh` reads the flake reference from an environment variable, so the long paths can be dropped.

## What Changes

- Enable home-manager's `programs.nh` in the MacBook's standalone home profile so the `nh` CLI is present in the user environment.
- Set the nh flake environment variable (`flake`) to the repository's absolute path, so `nh` resolves the repository flake from any working directory.
- `nh darwin switch` resolves its target automatically from the flake's `darwinConfigurations` hostname entry. Because the flake's home output is named after the short host alias (`luyan@macbook`) rather than the machine hostname, `nh home` actions select their target explicitly with `-c luyan@macbook`; the flake outputs are not renamed.
- Leave automatic garbage collection as-is (`nix.gc.automatic` in the shared host prelude); `programs.nh.clean` stays disabled to avoid a second, overlapping schedule.

## Capabilities

### New Capabilities
- `nh`: The MacBook home profile installs and configures the `nh` Nix helper against the repository flake.

### Modified Capabilities
<!-- none: the flake outputs and other hosts are unchanged -->

## Impact

- **Hosts affected**: macbook (standalone home-manager only).
- **Secrets / OpenTofu**: none.
- **Files**: `home-manager/luyan-macbook.nix` gains a `programs.nh` block; `flake.nix` is unchanged.

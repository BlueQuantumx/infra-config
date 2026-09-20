## Why

AeroSpace's tiling model and its accessibility requirements did not fit daily use on the MacBook, so window management moves to Rectangle: a keyboard- and drag-driven window snapper that leaves macOS window behaviour otherwise intact. AeroSpace is turned off rather than deleted, so switching back stays a one-line change.

## What Changes

- Stop importing `home-manager/modules/aerospace.nix` from the MacBook home profile. The module stays in the tree, dormant and documented, and the next activation removes its generated `~/.aerospace.toml` and its launchd agent.
- Add `home-manager/modules/rectangle.nix`, which declares Rectangle's preferences through `targets.darwin.defaults."com.knollsoft.Rectangle"` and is imported by the MacBook home profile.
- Declare the Rectangle application as a Homebrew cask in the MacBook darwin configuration (`hosts/macbook/configuration.nix`), so the app is updated by Homebrew and keeps its Developer ID signature — and therefore its accessibility grant — across upgrades.
- Deliberately do **not** enable home-manager's `programs.rectangle`: that module installs the preference file as a link into the Nix store, while Rectangle itself rewrites that file through `cfprefsd`, which would break later activations. Declared preferences instead merge into the real preference domain.
- Keyboard shortcuts are left at Rectangle's built-in defaults and remain adjustable in the app; in-app changes survive later switches because only declared keys are applied.

## Capabilities

### New Capabilities

- `rectangle`: the MacBook's Rectangle window snapping — how the application is installed, how its preferences are declared and applied, and what behaviour those preferences guarantee.

### Modified Capabilities

- `aerospace`: AeroSpace is no longer enabled on the MacBook; the requirements covering its generated config, daemon, package selection and window-management behaviour no longer describe the system.

## Impact

- **Hosts affected**: macbook (darwin configuration for the cask, standalone home-manager profile for the preferences).
- **Secrets / OpenTofu**: none — no sops files, no tofu state, no flake inputs added.
- **Files**: `home-manager/modules/rectangle.nix` (new), `home-manager/modules/aerospace.nix` (header only), `home-manager/luyan-macbook.nix` (import swap), `hosts/macbook/configuration.nix` (one cask).

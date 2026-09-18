## Why

The MacBook has no tiling window manager: window placement is manual and nothing in the repository manages window layout, workspaces, or per-application window rules. AeroSpace is an i3-like tiling window manager for macOS whose entire configuration is a single TOML file, so it can be owned declaratively by the standalone home profile alongside the other macOS tools.

## What Changes

- Add `home-manager/modules/aerospace.nix`, a macOS-gated home-manager module that enables `programs.aerospace`, generates the AeroSpace config from a Nix `settings` attribute, and declares the launchd agent that starts the daemon at login and keeps it alive.
- Import the module from the MacBook home profile (`home-manager/luyan-macbook.nix`); no other host or home profile changes.
- Ship a starter configuration: gaps, layout defaults, persistent workspaces, a main binding mode and a `service` mode.
- Select the AeroSpace package from `pkgs.unstable`: the 26.05 stable build (0.20.3) resets the macOS accessibility grant and terminates when the grant is missing, which turns the launchd keep-alive into a restart loop until the user grants the permission. The unstable build waits in-process instead.
- Granting the accessibility permission stays a manual, one-time macOS TCC action; it cannot be expressed in Nix.

## Capabilities

### New Capabilities

- `aerospace`: the MacBook's AeroSpace window management — generated config file, launchd-managed daemon lifecycle, workspace/keybinding behaviour, and per-application floating rules.

### Modified Capabilities

<!-- none: existing capabilities and other hosts are untouched -->

## Impact

- **Hosts affected**: macbook (standalone home-manager profile only).
- **Secrets / OpenTofu**: none — no sops files, no tofu state, no flake inputs added.
- **Files**: `home-manager/modules/aerospace.nix` (new), `home-manager/luyan-macbook.nix` (one import).

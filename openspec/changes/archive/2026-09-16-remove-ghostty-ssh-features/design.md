## Context

See proposal.md - Why. The only SSH-related setting in `home-manager/modules/ghostty.nix` is `shell-integration-features = "ssh-env,ssh-terminfo";`. Ghostty 1.3.1's built-in default is `cursor,no-sudo,title,no-ssh-env,no-ssh-terminfo,path` (verified with `ghostty +show-config --default`), so SSH integration is off unless explicitly enabled. Assigning this setting replaces the whole default list, meaning the current override also keeps cursor/title/path integration off.

## Goals / Non-Goals

**Goals:**
- Remove SSH shell-integration behavior from the MacBook's Ghostty terminal.
- Keep the change minimal and declarative, following existing home-manager module patterns.

**Non-Goals:**
- Choosing exactly which non-SSH shell-integration features are active (Ghostty defaults govern them).
- Changing any other Ghostty setting, host, or home config.

## Decisions

**Delete the `shell-integration-features` line rather than editing it.**
- Rationale: the line only lists SSH features, so deleting it removes exactly the unwanted behavior. Ghostty's defaults already disable SSH integration, so no replacement value is needed and the module gets simpler.
- Alternative considered: set `shell-integration-features = "cursor,title,path"` (or explicit `no-ssh-*` entries). Rejected as it hard-codes a feature list the user did not ask to control and duplicates the terminal's defaults.
- Trade-off accepted: `cursor`, `title`, and `path` integration become active again as a side effect of falling back to defaults.

## Risks / Trade-offs

- Restoring default shell-integration features is an observable change beyond SSH → noted in the spec ("falls back to Ghostty's built-in defaults") and in proposal assumptions; user can pin a specific list later if desired.
- Home-manager `programs.ghostty.settings` string rendering could leave an empty settings entry → verify with a dry-build that the generated config omits the key.

## Migration Plan

1. Delete the setting from `home-manager/modules/ghostty.nix`.
2. Rebuild the MacBook home config (`home-manager switch --flake .#luyan@macbook`) and optionally verify with `nix flake check`.
3. Rollback: `git revert` the commit (single-line deletion).

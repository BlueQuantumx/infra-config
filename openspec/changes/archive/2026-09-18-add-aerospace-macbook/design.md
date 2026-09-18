# Design

## Context

See `proposal.md` — Why. The MacBook is configured by two flake outputs: `darwinConfigurations."Louis-MacBook-Pro-2024"` (system) and the standalone `homeConfigurations."luyan@macbook"` (user). User-level tooling lives in `home-manager/modules/*.nix` and is imported by `home-manager/luyan-macbook.nix`; `home-manager/modules/ghostty.nix` establishes the pattern of a macOS-only module guarded on `pkgs.stdenv.hostPlatform.isDarwin`. The profile's `nixpkgs.overlays` already exposes the locked `nixpkgs-unstable` input as `pkgs.unstable` (`overlays/default.nix`), and `overlays/default.nix` documents the precedent of taking a faster-moving package from `pkgs.unstable` when the 26.05 channel lags.

AeroSpace is a GUI application that needs the macOS **Accessibility** permission (TCC) before it can manage windows. TCC grants cannot be expressed in Nix and, because an application installed from the store carries an ad-hoc signature, the recorded requirement is the binary's `cdhash` — so a binary change makes the previous grant stale.

## Goals / Non-Goals

**Goals:**

- One declarative source for both the AeroSpace config file and the daemon lifecycle, following the existing module layout.
- A daemon that is running after login and that recovers from crashes without user action.
- A first-run experience that degrades quietly while the accessibility grant is missing.

**Non-Goals:**

- Forcing workspaces onto specific monitors. Monitor names are unstable across dock/undock, and a workspace forced to a monitor that is not attached cannot be shown.
- Enabling `xdg.enable` in the profile to relocate generated files.
- Replacing macOS keybindings wholesale (no Karabiner-style remapping) — AeroSpace only takes over what the configuration binds.

## Decisions

**1. Use the home-manager `programs.aerospace` module instead of a checked-in `aerospace.toml`.**
The module generates the TOML from a Nix attribute set, filters nulls, writes the file, reloads the running daemon when the generated file changes, and wires the launchd agent. A hand-written config file was rejected: it would duplicate the configuration source and lose type-checked settings, reload-on-change and the agent wiring.

**2. Keep the config at the profile's default location (`~/.aerospace.toml`) instead of enabling XDG paths.**
The module writes to `$XDG_CONFIG_HOME/aerospace/aerospace.toml` only when `xdg.enable` is set, otherwise `~/.aerospace.toml`; AeroSpace reads both. Enabling `xdg.enable` would relocate generated files for every other module in the profile, a much wider blast radius than this change needs.

**3. Take the package from `pkgs.unstable`, not from the 26.05 stable channel.**
Stable 26.05 ships AeroSpace 0.20.3, whose startup path calls `tccutil reset Accessibility` and then terminates when the grant is missing. Combined with the agent's keep-alive that produced a restart loop — measured on the machine as 17 restarts in roughly three minutes, each re-triggering the permission prompt. The unstable build (0.21.3) instead waits in-process for the grant and proceeds once it is given. Alternatives: dropping keep-alive (rejected — loses crash recovery and auto-start, the loop is a first-run-only symptom), and the Homebrew cask (kept as fallback, see Risks).

**4. Declare the startup path in the module, not in the settings.**
The module forces `start-at-login = false` and `after-login-command = []`, and asserts when the settings try to set them; the launchd agent owns startup. The module therefore does not set `start-at-login`, and login behaviour comes from the agent's `RunAtLoad`/`KeepAlive`.

## Risks / Trade-offs

- **Ad-hoc signature ⇒ accessibility re-grant.** The store binary's TCC identity is its `cdhash`, so any change to the AeroSpace store path (typically a nixpkgs bump in `flake.lock`) makes the previous grant stale; AeroSpace clears the stale entry and waits for a new grant. → Documented in the module header. If re-granting becomes frequent enough to annoy, switch to the signed Homebrew cask (`nikitabobko/tap/aerospace`), which keeps a stable code requirement across updates at the cost of moving the app out of the store.
- **Package version drifts with `pkgs.unstable`.** → Version bumps arrive with ordinary flake updates; revert by bumping or pinning the input, or by returning to the stable channel once it ships a build with the waiting behaviour.
- **Accessibility permission is a manual step.** Nix cannot grant TCC. → The daemon waits in place, so the grant can be given at any time afterwards without restarting anything.
- **A display with no assigned workspace shows a stub workspace.** With no monitor force-assignment, AeroSpace keeps its stub workspace visible on the secondary display until a binding brings a configured workspace there. → Deliberate: see Non-Goals.

## Migration Plan

1. `home-manager switch --flake .#luyan@macbook` — writes the config file, installs the agent, starts the daemon.
2. Grant Accessibility to AeroSpace once in System Settings → Privacy & Security → Accessibility; the running daemon picks it up by itself.
3. Rollback: `git revert` the change and switch again. The next activation removes the generated config link and the agent; the store path may remain until the next garbage collection, and no system-level setting depends on it.

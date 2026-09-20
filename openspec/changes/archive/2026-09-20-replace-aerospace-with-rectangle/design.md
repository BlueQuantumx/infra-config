# Design

## Context

See `proposal.md` — Why. Until now the MacBook's window management was AeroSpace (archived change `2026-09-18-add-aerospace-macbook`). Two constraints shape this replacement:

- GUI applications on the MacBook are already managed as Homebrew casks declared in `hosts/macbook/configuration.nix` and installed through the `nix-homebrew` input; user-level preferences are declared in `home-manager/modules/*.nix` and imported by `home-manager/luyan-macbook.nix`.
- An application installed from the Nix store carries an ad-hoc signature, so its macOS accessibility (TCC) grant is keyed to the binary hash: every change of the store path invalidates the grant. A Developer ID-signed cask keeps a stable identity across upgrades.

## Goals / Non-Goals

**Goals:**

- Rectangle installed and updated as a signed application, with its accessibility grant surviving upgrades.
- Declared preferences applied to the real preference domain, leaving the application free to keep writing it.
- AeroSpace disabled with no residual daemon, agent or generated config, but re-enablable in one line.

**Non-Goals:**

- Declaring Rectangle's keyboard shortcuts in Nix. The application's built-in shortcuts stay in force and remain tunable in the app; freezing them in the profile would fight the user's own tuning.
- Restarting Rectangle automatically when a declared preference changes; the application reads preferences at launch (documented in the module instead).
- Deleting `home-manager/modules/aerospace.nix`. The request was to disable AeroSpace, and the module is the record of a configuration that may come back.

## Decisions

**1. Homebrew cask for the application, not `pkgs.rectangle`.**
`pkgs.rectangle` is built from source and therefore ad-hoc signed; its accessibility grant would be lost on every nixpkgs bump, exactly the friction that made AeroSpace awkward. The cask is Developer ID signed and notarized, so the grant persists. It also matches the MacBook's existing convention of casks for GUI applications.

**2. Home-manager's `programs.rectangle` module owns the preferences, with `package = null`.**
The module renders the declared preferences into `~/Library/Preferences/com.knollsoft.Rectangle.plist` as a home-manager link, which makes the declared keys the complete truth for that domain, and the cask owns the application binary in `/Applications`. The cost is measured and accepted: while the link is in place the domain is not writable by the application — `defaults read com.knollsoft.Rectangle` reports the domain as missing, `defaults write` fails with "Could not write domain", and Rectangle logs `Couldn't write values for keys … Path not accessible` — so settings changed in the app are not persisted and have to be declared here instead. The alternative that was prototyped and discarded, `targets.darwin.defaults."com.knollsoft.Rectangle"` with `defaults import` (which merges into a user-owned domain and keeps in-app changes), is therefore not used.

**3. Only behaviour preferences are declared.**
`launchOnLogin`, `gapSize` and `windowSnapping` are the choices that follow from "a window snapper that starts with the session and leaves a gap at the screen edges" — the same intent the AeroSpace configuration expressed. Everything else stays at Rectangle's defaults, so in-app tuning is not reverted. Note Rectangle's tri-state booleans: `windowSnapping` is stored as `1` (enabled) / `2` (disabled) / `0` (unset), unlike plain booleans such as `launchOnLogin`.

**4. Disable AeroSpace by dropping the import, keep the module.**
An unimported module has no effect: no launchd agent, no generated `~/.aerospace.toml`, no daemon. The module header states the current status and the two steps to re-enable it, and the `aerospace` capability is retired from the specs (the archived change keeps its design record).

**5. Declare Rectangle's drag-to-edge snapping as disabled, deferring drag snapping to macOS.**
macOS 15+ enables its own drag-to-edge tiling (`com.apple.WindowManager.EnableTilingByEdgeDrag`, enabled by default). While both are on, Rectangle raises a three-button conflict alert and, on "Disable in Rectangle", writes the disabled state into `windowSnapping` itself — so declaring it enabled is silently overridden and re-prompts on later launches. Measured on this machine: the declared `windowSnapping = 1` was rewritten to `2` by the application, and the preference file carried the app's own first-run keys alongside it. The declaration therefore states the disabled state explicitly, matching the choice made in that alert and keeping Rectangle in charge of the keyboard actions (its half actions were measured applying the declared 8px gap). The alternative — declaring snapping enabled and turning the macOS setting off in the darwin configuration — is a one-line change in each place and is left as an open question.

## Risks / Trade-offs

- **In-app preference changes do not persist.** The preference file is a home-manager link, so the application's writes fail (measured: `Couldn't write values for keys … Path not accessible`) and in-app changes have to be declared in the module instead. → Accepted with this design: every preference the user wants has to go into `programs.rectangle.defaults` (and `shortcuts`). Declaring nothing means running on the module's rendered file only.
- **Activation needs a clean preference path.** If a real preference file already occupies `~/Library/Preferences/com.knollsoft.Rectangle.plist`, home-manager stops with "Existing file … would be clobbered" unless `home-manager switch -b backup`, a configured `home-manager.backupFileExtension`/`backupCommand`, or `force = true` on that file entry is used. → The activation that first introduced the link needs one of those; this is observed on this machine while a real file written by the application was present.
- **Preferences are read at launch.** → Changing a declared value needs a Rectangle restart (or re-login). Stated in the module header; no activation hook, because killing the user's app during a switch is worse than a restart prompt.
- **The cask is reconciled by Homebrew, not by Home Manager.** The darwin configuration's activation needs sudo, so a `darwin-rebuild switch` runs it; until then the cask is installed by hand. → The declaration is what makes it reproducible; an already-installed cask is a no-op for `brew bundle`.
- **Rectangle also needs the accessibility permission.** → Its identity is stable, so the grant survives upgrades; the daemon-less design means no restart loop when the grant is missing (unlike the AeroSpace 0.20.3 behaviour).
- **Retiring the `aerospace` capability removes its spec.** → The module, its design and its requirements remain in the archived `2026-09-18-add-aerospace-macbook` change; re-enabling AeroSpace needs a fresh delta.

## Migration Plan

1. Drop the AeroSpace import and switch the home profile: the agent and the generated config are removed and the daemon stops.
2. Add the Rectangle module and cask; switch the home profile (preferences applied) and install the cask (instantly by hand, reconciled at the next darwin activation).
3. Launch Rectangle once and grant the accessibility permission.
4. Rollback: `git revert` the change and switch again. AeroSpace's capability and spec are recovered from the archived change.

## Open Questions

- Whether to declare a vim-style shortcut set for Rectangle in Nix, or keep tuning shortcuts in the application. Deferrable — the capability deliberately leaves shortcut assignment to the application.

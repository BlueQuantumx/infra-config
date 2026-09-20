## REMOVED Requirements

### Requirement: AeroSpace is owned by the MacBook home profile

**Reason**: AeroSpace is no longer used on the MacBook. Window management moved to Rectangle (see the `rectangle` capability). The module file stays in the repository, documented as dormant, and is not imported by any profile.
**Migration**: Import `home-manager/modules/aerospace.nix` from `home-manager/luyan-macbook.nix` again, then grant AeroSpace the macOS accessibility permission. Nothing else has to be restored.

### Requirement: The AeroSpace config file is generated from the Nix declaration

**Reason**: No profile enables AeroSpace, so no AeroSpace config file is generated and no daemon reloads it.
**Migration**: Re-importing the module regenerates the config file on the next home-manager activation.

### Requirement: The AeroSpace daemon is managed by a launchd agent

**Reason**: No profile enables AeroSpace, so its launchd agent is no longer declared. Deactivating the profile removes the agent and the running daemon.
**Migration**: Re-importing the module restores the agent, which starts the daemon at login, or `aerospace` can be started by hand in the meantime.

### Requirement: The selected package waits for the accessibility grant

**Reason**: The profile no longer installs an AeroSpace package, so no startup behaviour has to be guaranteed for it.
**Migration**: The module keeps its package selection; re-importing the module restores the requirement as well.

### Requirement: Window management behaviour is declared in the profile

**Reason**: AeroSpace's binding modes, persistent workspaces, gaps and floating rules are inactive. Rectangle now provides the MacBook's window actions.
**Migration**: Re-importing the module restores the declared keybindings, workspaces, gaps and floating rules.

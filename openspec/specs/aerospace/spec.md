# aerospace Specification

## Purpose

Declares how the MacBook's AeroSpace tiling window manager is configured from the repository: which module owns it, where its generated config file lands, how the daemon starts and stays alive, and what window-management behaviour the configuration guarantees.

## Requirements

### Requirement: AeroSpace is owned by the MacBook home profile

The MacBook home profile SHALL declare its AeroSpace window-management configuration in `home-manager/modules/aerospace.nix` and import it from `home-manager/luyan-macbook.nix`, so the whole setup is reproducible from the flake with no hand-maintained state outside the repository. Enabling AeroSpace SHALL be scoped to Darwin, and other hosts and home profiles SHALL NOT enable it.

#### Scenario: Module declares and enables AeroSpace

- **WHEN** `nix eval .#homeConfigurations."luyan@macbook".config.programs.aerospace.enable` is evaluated
- **THEN** it returns `true`, and the declaration lives in `home-manager/modules/aerospace.nix` rather than in the profile's top-level options

#### Scenario: Other hosts are unaffected

- **WHEN** the flake's other host and home-manager configurations are evaluated
- **THEN** none of them enable the AeroSpace module and none declare an AeroSpace launchd agent

### Requirement: The AeroSpace config file is generated from the Nix declaration

The profile SHALL generate AeroSpace's TOML configuration from the module's Nix `settings` attribute rather than from a checked-in file, and SHALL place it in one of the config locations AeroSpace reads. The generated config SHALL NOT take over its own login startup, because the launchd agent owns the daemon lifecycle.

#### Scenario: Generated file lands in an AeroSpace config location

- **WHEN** the MacBook home profile is activated
- **THEN** the generated config file exists at a path AeroSpace reads for its user configuration, and it is a home-manager link into the profile generation

#### Scenario: Startup keys are left to launchd

- **WHEN** the generated config file is inspected
- **THEN** it does not ask AeroSpace to start at login or to run its own login commands

#### Scenario: Edited settings reach the running daemon

- **WHEN** a setting in the module is changed and the home profile is switched again
- **THEN** the generated config file changes accordingly and the running AeroSpace reloads it

### Requirement: The AeroSpace daemon is managed by a launchd agent

The profile SHALL declare a launchd agent whose program is the AeroSpace application bundle taken from the profile's AeroSpace package, and the agent SHALL run at login and keep the daemon alive so a crash recovers without user action.

#### Scenario: Agent is declared in the evaluated profile

- **WHEN** `nix eval .#homeConfigurations."luyan@macbook".config.launchd.agents.aerospace` is evaluated
- **THEN** the agent is enabled, runs at load, keeps the process alive, and its program path resolves inside the store path of the profile's AeroSpace package

#### Scenario: Daemon is running after login

- **WHEN** the user logs in to the MacBook with the accessibility permission already granted
- **THEN** the AeroSpace daemon is running under the agent's label without the user starting it by hand

### Requirement: The selected package waits for the accessibility grant

The profile SHALL select an AeroSpace build whose startup path waits for the macOS accessibility grant instead of terminating, so that a missing grant cannot turn the agent's keep-alive into a restart loop that repeatedly re-prompts for the permission.

#### Scenario: Missing grant does not cause a restart loop

- **WHEN** the daemon starts while the accessibility permission has not been granted
- **THEN** the process stays resident and waits instead of exiting, so the agent reports a running job rather than an increasing restart count

#### Scenario: Window management starts after the grant

- **WHEN** the accessibility permission is granted while the daemon is already running
- **THEN** the daemon begins managing windows without being restarted by hand

### Requirement: Window management behaviour is declared in the profile

The configuration SHALL define the main binding mode so that focus movement, window movement, resizing, workspace switching, moving a window to a workspace, layout switching, fullscreen toggling and window closing are all reachable from the keyboard, plus a secondary service mode for layout-reset and join operations. It SHALL keep a persistent workspace set so workspaces survive without windows, SHALL apply a consistent gap between and around tiles, and SHALL open applications designated as panels as floating windows.

#### Scenario: Bindings are part of the effective configuration

- **WHEN** the running daemon's effective config path and its main-mode binding keys are queried
- **THEN** the reported config path is the generated file and the declared bindings are present

#### Scenario: Workspaces survive being emptied

- **WHEN** the running daemon lists all workspaces without any managed window present
- **THEN** it lists the configured persistent workspace set

#### Scenario: Panel applications float

- **WHEN** a window of an application designated as a panel is detected
- **THEN** that window's parent container layout is floating rather than tiled

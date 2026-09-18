## Purpose

Provides the `nh` Nix helper on the MacBook's standalone home profile, preconfigured with the repository flake so the common switch and cleanup operations can be run from any directory.

## ADDED Requirements

### Requirement: nh is available in the MacBook home profile

The MacBook home profile SHALL install the `nh` package by enabling `programs.nh`, so an interactive shell on the MacBook can invoke `nh` without an ad-hoc `nix shell`.

#### Scenario: nh on PATH after home-manager switch

- **WHEN** a user runs the MacBook home-manager switch and opens a new interactive shell
- **THEN** `nh --version` resolves to the `nh` package provided by the home profile

#### Scenario: nh configuration lives in the MacBook profile

- **WHEN** the MacBook home module set is inspected
- **THEN** the `nh` enablement and its flake default are declared in `home-manager/luyan-macbook.nix`, with no change to other hosts or home profiles

### Requirement: nh resolves the repository flake from any directory

The MacBook home profile SHALL set the `nh` flake environment variable to the repository's absolute flake path, so `nh` commands resolve the repository flake without a path argument regardless of the working directory.

#### Scenario: flake environment variable is exported

- **WHEN** the MacBook home profile is evaluated
- **THEN** the nh flake environment variable is set to the repository's absolute path

#### Scenario: darwin command resolves its target automatically

- **WHEN** a user runs an `nh darwin` action (for example `nh darwin switch`) from outside the repository
- **THEN** nh resolves the flake and the MacBook Darwin configuration without the user supplying a path or target on the command line

#### Scenario: home command resolves with the configuration name

- **WHEN** a user runs an `nh home` action (for example `nh home switch -c luyan@macbook`) from outside the repository
- **THEN** nh resolves the flake and the MacBook home configuration without the user supplying a flake path on the command line

### Requirement: nh does not add a second garbage-collection schedule

Enabling `nh` SHALL NOT enable `programs.nh.clean`, so the MacBook keeps a single garbage-collection schedule from the shared host prelude rather than two overlapping schedules.

#### Scenario: No nh-clean agent is installed

- **WHEN** the MacBook home profile is evaluated
- **THEN** no `nh clean` launchd agent is declared by the profile

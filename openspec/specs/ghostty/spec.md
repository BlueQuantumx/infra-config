# ghostty Specification

## Purpose

Defines the contract for the MacBook's Ghostty terminal configuration, managed declaratively as a home-manager module so the terminal's shell-integration behavior is reproducible and does not enable SSH-specific integration.

## Requirements

### Requirement: Ghostty configuration managed by the home-manager module

The MacBook's Ghostty terminal SHALL be configured declaratively through the dedicated home-manager module (`home-manager/modules/ghostty.nix`), and that module SHALL be the only place its terminal settings are declared.

#### Scenario: Ghostty module is imported into the MacBook home config

- **WHEN** the `luyan@macbook` home-manager configuration is evaluated
- **THEN** the Ghostty module is part of the imported module set and `programs.ghostty.enable` is true in the resulting configuration

### Requirement: SSH shell-integration features stay disabled

The Ghostty configuration SHALL NOT enable SSH-related shell-integration features, so the terminal does not inject SSH environment or terminfo handling into the shell.

#### Scenario: Effective shell-integration features exclude SSH

- **WHEN** the effective Ghostty settings from the home-manager module are resolved
- **THEN** no SSH-related shell-integration feature is enabled, and the terminal falls back to Ghostty's built-in defaults for the remaining shell-integration features

#### Scenario: No SSH shell-integration override in the module

- **WHEN** the Ghostty module source is inspected
- **THEN** it contains no `shell-integration-features` setting that turns SSH integration on

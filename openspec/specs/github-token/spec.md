# github-token

## Purpose

Declaratively provision a `GITHUB_TOKEN` environment variable on the MacBook from a sops-encrypted secret, wired through sops-nix's home-manager module so the imperative keyring token is no longer required.

## Requirements

### Requirement: GITHUB_TOKEN provisioned on the MacBook

The MacBook home-manager configuration SHALL provision a `GITHUB_TOKEN` environment variable whose value is decrypted from the sops secret `github_token` in `secrets/common.yaml`.

#### Scenario: Token exported in interactive shell

- **WHEN** a user opens an interactive shell on the MacBook after `home-manager switch --flake .#luyan@macbook`
- **THEN** `GITHUB_TOKEN` is set to the decrypted value of the `github_token` secret

### Requirement: sops-nix home-manager module wired into MacBook config

The MacBook home config SHALL import `inputs.sops-nix.homeManagerModules.sops` and configure it with `age.sshKeyPaths` pointing at the existing `client` SSH key.

#### Scenario: sops module present in the MacBook home config

- **WHEN** the MacBook home config is evaluated
- **THEN** the sops-nix home-manager module is imported and decryption uses the `client` SSH key at `/Users/luyan/.ssh/sops`

### Requirement: Secret decrypted only on the MacBook

The change SHALL NOT alter the NixOS hosts (`raspi`, `azure`) or the `orb`/`raspi` home-manager configs.

#### Scenario: Other hosts unchanged

- **WHEN** `nix flake check` runs
- **THEN** the NixOS and home-manager configurations for `raspi`, `azure`, and `orb` remain unchanged

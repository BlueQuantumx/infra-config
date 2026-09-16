## MODIFIED Requirements

### Requirement: GITHUB_TOKEN provisioned on the MacBook

The MacBook home-manager configuration SHALL provision a `GITHUB_TOKEN` environment variable whose value is decrypted from the sops secret `github_token` in the MacBook-scoped secrets file.

#### Scenario: Token exported in interactive shell

- **WHEN** a user opens an interactive shell on the MacBook after `home-manager switch --flake .#luyan@macbook`
- **THEN** `GITHUB_TOKEN` is set to the decrypted value of the `github_token` secret

### Requirement: Secret decrypted only on the MacBook

The `github_token` secret SHALL be scoped to the administration key, so that no NixOS host is a recipient of it.

#### Scenario: Other hosts unchanged

- **WHEN** `nix flake check` runs
- **THEN** the NixOS and home-manager configurations for `raspi`, `azure`, and `orb` continue to evaluate

#### Scenario: NixOS hosts cannot decrypt the token

- **WHEN** the MacBook-scoped secrets file is presented on a NixOS host
- **THEN** decryption fails because that host is not a recipient

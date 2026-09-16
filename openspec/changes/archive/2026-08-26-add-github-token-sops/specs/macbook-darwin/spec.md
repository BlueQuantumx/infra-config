## ADDED Requirements

### Requirement: MacBook home config exposes GITHUB_TOKEN via sops

The `homeConfigurations."luyan@macbook"` configuration SHALL export a `GITHUB_TOKEN` shell environment variable sourced from a sops-encrypted secret, so the MacBook no longer relies on the imperative keyring token.

#### Scenario: GITHUB_TOKEN available after home-manager switch

- **WHEN** a user runs `home-manager switch --flake .#luyan@macbook` on the MacBook
- **THEN** a new interactive shell has `GITHUB_TOKEN` set to the decrypted `github_token` secret

#### Scenario: sops-nix module imported in the MacBook home config

- **WHEN** the `luyan@macbook` home-manager module set is evaluated
- **THEN** the `sops-nix` home-manager module is imported and configured with the `client` SSH key for decryption

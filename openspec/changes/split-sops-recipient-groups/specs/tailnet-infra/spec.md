## MODIFIED Requirements

### Requirement: Minted keys reach hosts through sops

A flake app SHALL read the stack's sensitive key outputs and write each minted auth key into the sops-encrypted secrets file scoped to the host(s) that consume that key, so hosts read keys through sops-nix and no plaintext key is committed. Each written file's recipient group SHALL contain only that key's consuming hosts and the administration key. Only an encrypted diff SHALL result.

#### Scenario: Bridge leaves only an encrypted diff

- **WHEN** the bridge app runs after the tailnet stack is applied
- **THEN** the secrets files are updated in place with the minted keys
- **AND** the resulting change is encrypted, not plaintext

#### Scenario: Hosts consume keys via sops-nix

- **WHEN** a NixOS host references a tailnet auth key
- **THEN** it reads the decrypted value from a sops-nix secret path

#### Scenario: Each key lands in its consumer's scoped file

- **WHEN** the bridge app runs
- **THEN** each minted key is written into the secrets file whose recipient group contains that key's consumer host

#### Scenario: Only consumers can read a minted key

- **WHEN** a host that does not consume a given tailnet auth key is presented the file holding it
- **THEN** decryption fails because that host is not a recipient

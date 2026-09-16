## Purpose

Define how sops-encrypted secrets are scoped to recipient groups so each secrets file is readable only by the hosts that consume it, plus the administration key.

## ADDED Requirements

### Requirement: Secrets files are scoped to their consumer hosts

Each sops-encrypted secrets file SHALL be encrypted only to the identities of the hosts that decrypt it, together with the administration key. A host that does not consume a file MUST NOT be a recipient of it.

#### Scenario: Consumer host decrypts its file

- **WHEN** a host activates sops-nix with a secret declared from a file scoped to that host
- **THEN** the secret decrypts successfully

#### Scenario: Non-consumer host cannot decrypt

- **WHEN** a host that is not a listed recipient is asked to decrypt a secrets file
- **THEN** decryption fails

### Requirement: The administration key is a member of every group

The sops administration key SHALL remain a recipient of every recipient group, so secrets stay editable and any secret-writing flake app keeps working from the administration workstation.

#### Scenario: Secrets stay editable from the workstation

- **WHEN** an encrypted secrets file is opened for editing from the administration workstation
- **THEN** decryption succeeds

### Requirement: Hosts do not read each other's scoped secrets

A host MUST NOT be a recipient of secrets scoped to a different host. A secret consumed by more than one host SHALL live in a file whose recipient group lists exactly those consumers plus the administration key.

#### Scenario: One host cannot read another host's scoped file

- **WHEN** a host's scoped secrets file is presented to a different host
- **THEN** decryption fails because that host is not a recipient

#### Scenario: A shared secret lists exactly its consumers

- **WHEN** a secret is consumed by more than one host
- **THEN** its file's recipient group contains those consumers and the administration key, and no other host

### Requirement: Only active consumers are recipients

A host that does not consume any secret MUST NOT appear as a recipient in any creation rule.

#### Scenario: Host without sops wiring is not a recipient

- **WHEN** a host's configuration neither enables sops-nix nor declares any sops secret
- **THEN** that host's identity does not appear in any creation rule

### Requirement: Re-scoping preserves secret values

Splitting or re-scoping recipient groups SHALL preserve every existing secret key and value; only the set of recipients changes.

#### Scenario: No secret is dropped

- **WHEN** a secrets file is re-encrypted under a new recipient group
- **THEN** the set of decrypted keys and values is unchanged from before

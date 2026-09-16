# tailnet-infra Specification

## Purpose

Defines the OpenTofu-managed tailnet control plane: an isolated stack that owns the tailnet ACL, tags and exit-node approval, mints per-node tagged auth keys, manages the tailnet DNS preference, and bridges those keys into sops so hosts can consume them.

## Requirements

### Requirement: Tailnet control plane is an isolated OpenTofu stack

The tailnet SHALL be managed by an OpenTofu stack separate from the Azure infrastructure stack, with its own state. Planning or applying the tailnet SHALL NOT read or modify the Azure VM and its networking.

#### Scenario: Tailnet plan is independent of Azure

- **WHEN** the tailnet stack is planned
- **THEN** it operates on tailnet resources only, using its own state key
- **AND** no Azure resource changes are proposed

### Requirement: Provider credentials come from the environment

Credentials for the tailnet provider SHALL be supplied through environment variables and SHALL NOT be committed to the repository or emitted into generated Nix/OpenTofu values.

#### Scenario: No committed credential

- **WHEN** the tailnet stack is planned or applied
- **THEN** the provider authenticates from environment variables
- **AND** no provider credential appears in tracked files or generated variables

### Requirement: Per-node tagged auth keys are minted by the stack

The stack SHALL create a pre-authorized, reusable auth key for each node (`azure`, `raspi`, `mac`) and expose each as a sensitive output. Keys SHALL carry tags that distinguish exit-capable servers from clients.

#### Scenario: One tagged key per node

- **WHEN** the tailnet stack is applied
- **THEN** one auth key exists per node
- **AND** each key carries the tag(s) appropriate to that node's role
- **AND** each key value is marked sensitive

### Requirement: The ACL is the single owner of exit-node approval

The stack SHALL manage the tailnet ACL, including tag ownership and automatic approval of advertised exit nodes for the exit tag. Exit-node approval SHALL NOT also be managed per device, to avoid configuration drift between the two owners.

#### Scenario: Exit nodes are auto-approved via policy

- **WHEN** a node carrying the exit tag advertises itself as an exit node
- **THEN** the advertisement is approved by the ACL policy
- **AND** no per-device route resource duplicates that approval

### Requirement: Tailnet DNS preference is managed declaratively

The stack SHALL manage the tailnet's MagicDNS preference so it is reproducible rather than set by hand in the control panel.

#### Scenario: MagicDNS is declared in the stack

- **WHEN** the tailnet stack is applied
- **THEN** the MagicDNS preference reflects the declared value

### Requirement: Minted keys reach hosts through sops

A flake app SHALL read the stack's sensitive key outputs and write them into the sops-encrypted secrets file, so hosts consume keys through sops-nix and no plaintext key is committed. Only an encrypted diff SHALL result.

#### Scenario: Bridge leaves only an encrypted diff

- **WHEN** the bridge app runs after the tailnet stack is applied
- **THEN** the secrets file is updated in place with the minted keys
- **AND** the resulting change is encrypted, not plaintext

#### Scenario: Hosts consume keys via sops-nix

- **WHEN** a NixOS host references a tailnet auth key
- **THEN** it reads the decrypted value from a sops-nix secret path

### Requirement: The tailnet stack exposes flake apps

The flake SHALL expose plan and apply apps for the tailnet stack, consistent with the existing OpenTofu apps, so the stack is driven through flake outputs rather than manual `tofu` invocations in the wrong directory.

#### Scenario: Running the tailnet plan app

- **WHEN** a user runs the tailnet plan or apply app
- **THEN** it operates in the tailnet stack directory and regenerates any generated variables first

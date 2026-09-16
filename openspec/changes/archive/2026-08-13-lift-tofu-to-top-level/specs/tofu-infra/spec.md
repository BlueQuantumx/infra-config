## ADDED Requirements

### Requirement: Top-level tofu directory

The OpenTofu configuration SHALL live at a top-level `tofu/` directory in the repository root, independent of any single NixOS host directory. This signals that tofu manages personal infra, not one host's resources.

#### Scenario: Repo layout after relocation

- **WHEN** the change is applied
- **THEN** the directory `tofu/` exists at the repository root containing `main.tf`, `nixos.tf`, `outputs.tf`, `providers.tf`, `variables.tf`, `terraform.tfvars` (gitignored), `terraform.tfvars.json` (generated), `bootstrap/`, and `defaults.nix`
- **AND** the directory `hosts/azure/tofu/` no longer exists
- **AND** the file `hosts/azure/defaults.nix` no longer exists (its contents were moved to `tofu/defaults.nix`)

#### Scenario: Defaults file is single source of truth

- **WHEN** any NixOS host config or the tofu stack needs shared infra values (hostname, domain, subdomains, Azure knobs, EasyTier ports)
- **THEN** those values are imported from `tofu/defaults.nix`
- **AND** `hosts/azure/*.nix` files import from `../../tofu/defaults.nix` rather than a local `./defaults.nix`

### Requirement: Flake exposes tofu as infra, not as an azure-host concern

The flake SHALL expose `tofuVars`, the `tofu-vars` app, and the `tofu-plan` / `tofu-apply` apps as personal-infra-wide helpers, with no hardcoded `hosts/azure/` path.

#### Scenario: tofu-app target directory

- **WHEN** the user runs `nix run .#tofu-plan` or `nix run .#tofu-apply`
- **THEN** the app cds into the repository-root `tofu/` directory (not `hosts/azure/tofu/`) before invoking `${pkgs.opentofu}/bin/tofu`

#### Scenario: tofu-vars regenerates tfvars at the new path

- **WHEN** the user runs `nix run .#tofu-vars`
- **THEN** the file `tofu/terraform.tfvars.json` is regenerated from the `tofuVars` flake output
- **AND** `tofuVars` is built from the values imported via `import ./tofu/defaults.nix` (the binding renamed from `azureDefaults` to `infraDefaults` is an implementation detail; the observable values are unchanged)

#### Scenario: tofuVars values are stable across the move

- **WHEN** the user runs `nix eval .#tofuVars --json` before and after the change
- **THEN** the JSON output is identical (same keys, same values) — the move does not alter any infra variable

### Requirement: Azure Linux VM and supporting resources

The tofu stack SHALL provision (unchanged from today): one Azure resource group, one virtual network with one subnet, one network security group with inbound SSH/HTTP/HTTPS/EasyTier-TCP/EasyTier-UDP rules associated to the subnet, one static Standard-SKU public IP, one network interface with that public IP, and one `Standard_B2ats_v2` Ubuntu 22.04 LTS Gen2 Linux VM with password auth disabled and the configured SSH public key installed.

#### Scenario: VM and networking resources exist after apply

- **WHEN** `nix run .#tofu-apply` runs successfully against an authenticated Azure subscription
- **THEN** all resources named in `tofu/main.tf` are created in the `eastasia` region under resource group `nixos-azure`
- **AND** the VM exposes SSH (22), HTTP (80), HTTPS (443), EasyTier TCP ports (`[61070]`), and EasyTier UDP ports (`[61070, 61071, 11013]`) inbound from `0.0.0.0/0`

### Requirement: Cloudflare A records pointing at the Azure VM

The tofu stack SHALL create two non-proxied (DNS-only) Cloudflare A records in the configured personal domain zone, both pointing at the Azure VM public IP: `<subdomain_substore>.<domain>` (today `sub.egrecho47.top`) and `<subdomain_azure>.<domain>` (today `azure.egrecho47.top`).

#### Scenario: DNS records resolve to the VM IP after apply

- **WHEN** `nix run .#tofu-apply` completes
- **THEN** resolving `sub.egrecho47.top` and `azure.egrecho47.top` returns the Azure VM public IP

### Requirement: nixos-anywhere provisioner installs the azure NixOS host

A `null_resource` provisioner SHALL run `nixos-anywhere --build-on remote --flake "${path.module}/../..#azure" <admin>@<vm_public_ip>` after the VM is created, installing the `#azure` NixOS flake output onto the VM.

#### Scenario: Provisioner flake reference is unaffected by the move

- **WHEN** the tofu directory moves from `hosts/azure/tofu/` to `tofu/`
- **THEN** the `nixos-anywhere --flake` argument still resolves to the same NixOS configuration output (`#azure`), because `../..` from `tofu/` still points to the repository root (same as `../..` from `hosts/azure/tofu/` did)

### Requirement: State stored under a renamed backend key

The tofu backend SHALL be `azurerm` with state stored in the `rg-tfstate` resource group, storage account `nixcfgtfstate7867`, container `tfstate`, at **key `tofu.tfstate`** (formerly `hosts/azure/tofu.tfstate`).

#### Scenario: First plan after state migration shows no diffs

- **WHEN** the existence state blob is copied from `hosts/azure/tofu.tfstate` to `tofu.tfstate` in Azure storage, AND `tofu/providers.tf` is updated to use the new key, AND `nix run .#tofu-plan` is run
- **THEN** the plan reports no changes (the move is transparent to OpenTofu — resources are unchanged and state is intact under the new key)

#### Scenario: Old state key retained as backup

- **WHEN** the state migration is performed
- **THEN** the original blob at key `hosts/azure/tofu.tfstate` is preserved (not deleted) so it can be used as a rollback reference until the change is confirmed stable

### Requirement: Subscription id stays out of git

The `subscription_id` variable SHALL remain sourced from the gitignored `tofu/terraform.tfvars` file (the only variable not generated from `tofu/defaults.nix`); it SHALL NOT be committed to the repository or appear in `tofu/terraform.tfvars.json`.

#### Scenario: subscription_id path after relocation

- **WHEN** the tofu directory moves to `tofu/`
- **THEN** the file `tofu/terraform.tfvars` is gitignored and contains the `subscription_id` value
- **AND** the generated `tofu/terraform.tfvars.json` (from `tofuVars`) does not include `subscription_id`
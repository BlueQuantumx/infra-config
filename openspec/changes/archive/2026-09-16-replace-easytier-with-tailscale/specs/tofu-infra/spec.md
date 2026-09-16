## MODIFIED Requirements

### Requirement: Azure Linux VM and supporting resources

The tofu stack SHALL provision: one Azure resource group, one virtual network with one subnet, one network security group associated to the subnet, one static Standard-SKU public IP, one network interface with that public IP, and one `Standard_B2ats_v2` Ubuntu 22.04 LTS Gen2 Linux VM with password auth disabled and the configured SSH public key installed. The network security group SHALL always allow inbound SSH, HTTP and HTTPS, and SHALL add inbound EasyTier TCP/UDP rules only when the optional EasyTier fallback is enabled.

#### Scenario: VM and networking resources exist after apply

- **WHEN** `nix run .#tofu-apply` runs successfully against an authenticated Azure subscription
- **THEN** all resources named in `tofu/main.tf` are created in the `eastasia` region under resource group `nixos-azure`
- **AND** the VM exposes SSH (22), HTTP (80), and HTTPS (443) inbound from `0.0.0.0/0`

#### Scenario: EasyTier rules follow the fallback flag

- **WHEN** the EasyTier fallback is disabled
- **THEN** the network security group opens no EasyTier TCP/UDP rules
- **AND** the shared EasyTier port values are still supplied to OpenTofu
- **AND** when the fallback is enabled, those inbound rules are present

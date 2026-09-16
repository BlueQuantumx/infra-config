## Why

The OpenTofu config currently lives under `hosts/azure/tofu/` and its flake wiring (`tofuVars`, `tofuApp`, `tofuVarsApp`) hardcodes that path and reads only from `hosts/azure/defaults.nix`. This frames the tofu config as belonging to the `azure` NixOS host, when in fact it is **personal infra config** that should be independent of any single host. Lifting it to a top-level `tofu/` directory makes the intent explicit and keeps the door open for non-Azure resources without restructuring again.

## What Changes

- `git mv hosts/azure/tofu tofu/` — relocate the OpenTofu stack to the repo root.
- `git mv hosts/azure/defaults.nix tofu/defaults.nix` — lift the shared defaults file to its new home alongside the tofu config.
- Update `flake.nix`: import path becomes `./tofu/defaults.nix`; rename binding `azureDefaults` → `infraDefaults`; `tofuDir` becomes `"tofu"` (in `tofuApp` and `tofuVarsApp`).
- Update `hosts/azure/*.nix` consumers of `./defaults.nix` to import from the new path (`../../tofu/defaults.nix`).
- Update stale path references in comments inside `tofu/variables.tf`, `tofu/providers.tf` backend block, `tofu/defaults.nix` header, and `hosts/azure/README.md` if present.
- **BREAKING (state)**: change the azurerm backend `key` from `"hosts/azure/tofu.tfstate"` to `"tofu.tfstate"`. Requires a one-time state migration: copy the blob in Azure storage to the new key before the next plan. A clean `tofu plan` afterward must show no diffs.

No behavioral changes: tofu still provisions the same Azure VM, public IP, NSG rules, and two Cloudflare A records; `nixos-anywhere` still installs the `#azure` NixOS flake output. Variable names in `variables.tf` (`vm_size`, `location`, `name_prefix`, etc.) are intentionally left Azure-flavored — renaming to `azure_*` is pre-optimization until a second provider's variables exist.

## Capabilities

### New Capabilities

- `tofu-infra`: formalizes the OpenTofu-managed personal infrastructure: provisions one Azure Linux VM with NSG rules, public IP, and two Cloudflare A records; runs `nixos-anywhere` to install the `#azure` NixOS flake output; tfstate is stored in an Azure storage account. No prior spec existed; this change introduces one alongside the relocation.

### Modified Capabilities

<!-- None — this is the first spec for tofu-infra. -->

## Impact

- **Hosts affected**: `azure` (NixOS host config still consumes the lifted defaults file; tofu is no longer under `hosts/azure/` but provisions the same VM). Other hosts (`macbook`, `orb`, `raspi`, `digital-ocean`, `home-manager`) are untouched.
- **OpenTofu state involved**: yes — backend key rename requires a blob copy in Azure storage (`rg-tfstate` / `nixcfgtfstate7867` / container `tfstate`). Old blob retained as backup. New key: `tofu.tfstate`.
- **Secrets**: none touched; `tofu/terraform.tfvars` (gitignored, holds `subscription_id`) is relocating but its content is unchanged.
- **Code paths touched**: `flake.nix`, `hosts/azure/configuration.nix` (and any other `hosts/azure/*.nix` reading `./defaults.nix`), `tofu/defaults.nix` (header comment), `tofu/variables.tf` (header comment), `tofu/providers.tf` (backend `key`).
- **Verification**: `nix flake check`, `nix eval .#tofuVars --json` (values unchanged), `nix run .#tofu-vars` (regenerates `tofu/terraform.tfvars.json`), `nix run .#tofu-plan` (must be clean post-migration), `nixos-rebuild dry-build --flake .#azure`.
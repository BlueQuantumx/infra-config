## Context

The OpenTofu config has grown into a single personal-infra stack but lives under `hosts/azure/tofu/`, framed as belonging to the `azure` NixOS host. Today the tofu stack provisions: one Azure Linux VM (`Standard_B2ats_v2` in `eastasia`), its networking (RG, VNet, subnet, NSG with SSH/HTTP/HTTPS/EasyTier rules, public IP, NIC), two Cloudflare A records pointing at the VM, an `azurerm` backend storing tfstate inside Azure itself (`rg-tfstate` storage account), and a `null_resource` that runs `nixos-anywhere` to install the `#azure` NixOS flake output.

Coupling points to address:

```
flake.nix
  ├── azureDefaults = import ./hosts/azure/defaults.nix
  ├── tofuVars { ... } from azureDefaults
  ├── tofuApp (cmd) → tofuDir = "hosts/azure/tofu"
  └── tofuVarsApp → writes "hosts/azure/tofu/terraform.tfvars.json"

hosts/azure/
  ├── defaults.nix                       ← single source of truth (mixed concerns)
  ├── tofu/                              ← the IaC stack
  │   ├── providers.tf                   ← backend key = "hosts/azure/tofu.tfstate"
  │   ├── variables.tf                   ← header comments reference the old path
  │   ├── nixos.tf                       ← ../..#azure flake ref (still works after move)
  │   └── ...
  ├── configuration.nix                  ← consumes ./defaults.nix
  └── (other azure *.nix files)

openspec/specs/                          ← none — tofu has no behavior spec today
```

The intent of the change is **(A) one tofu stack, single-stack behavior preserved** — only the framing and physical location change, not how tofu runs.

## Goals / Non-Goals

**Goals:**

- Relocate `hosts/azure/tofu/` to a top-level `tofu/` directory, preserving git history via `git mv`.
- Lift `hosts/azure/defaults.nix` to `tofu/defaults.nix` so the infra defaults file lives next to the IaC stack it primarily feeds.
- Update all `flake.nix` wiring (`tofuDir`, `tofuVars`, `tofuVarsApp`, binding rename) so the tofu helpers are framed as personal-infra helpers, not azure-host helpers.
- Update `hosts/azure/*.nix` consumers to import the lifted defaults from `../../tofu/defaults.nix`.
- Rename the azurerm backend state key from `hosts/azure/tofu.tfstate` to `tofu.tfstate` and migrate the existing state blob so the next plan is clean.
- Introduce a `tofu-infra` behavior spec (first one for tofu) so the contract is explicit.

**Non-Goals:**

- Not renaming `variables.tf` keys to `azure_*`. That's pre-optimization until a second cloud provider's variables need disambiguation.
- Not splitting DNS records into a separate `dns` stack. A `(B)`-style multi-stack restructure is explicitly deferred.
- Not changing the azurerm backend to a different backend (R2, local, etc.). State still lives in Azure — the only change is the blob key inside Azure storage.
- Not renaming the `#azure` NixOS flake output. The NixOS host is still called `azure`; only the tofu directory moved.
- Not introducing Terraform modules for VM/networking/DNS. The current monolithic `main.tf` stays — restructuring HCL composition is unrelated to the relocation.
- Not provisioning any new clouds beyond Azure. The "universal personal infra" framing is about readiness/structure, not about adding a DigitalOcean stack today.

## Decisions

### D1: Use `git mv` for both files rather than `cp` + `rm`

**Why:** preserves rename history in `git log --follow` and avoids showing the change as a delete+add. Cheap and correct.

**Alternatives considered:** `cp` + `git rm` — same end state, loses rename detection for large files. Rejected.

### D2: Lift `defaults.nix` to `tofu/defaults.nix` rather than a top-level `defaults.nix`

**Why:** the defaults file is the primary source of truth for the tofu stack (every `tofuVars` entry comes from it). Hosting it next to the HCL files keeps the "infra defaults" mental model local to infra. The `hosts/azure/*.nix` consumers reach up two directories via `../../tofu/defaults.nix`, which is the standard Nix pattern for cross-host imports already used elsewhere in the flake.

**Alternatives considered:**
- Keep `hosts/azure/defaults.nix` and have tofu import it from there — contradicts the goal of decoupling tofu from the azure host directory; rejected.
- New top-level `defaults.nix` — adds a top-level file that's only consumed by tofu; rejected in favor of co-location with tofu.

### D3: Keep `variables.tf` keys Azure-flavored (`vm_size`, `location`, `name_prefix`, …)

**Why:** there is only one provider today. Adding a `azure_` prefix to every variable would be premature disambiguation — it would be churn for no behavioral gain and make the (eventual) second-provider migration *more* painful because each rename would need to be remembered. When a second cloud's variables do appear, the rename can be done as a small focused PR.

### D4: Rename the azurerm backend key and migrate the state blob

**Why:** keeping the old key (`hosts/azure/tofu.tfstate`) would leave stale path references wired into the production state location, contradicting the framing change. The migration is one `az storage blob copy` command (or a portal copy) — `tofu state push`/`pull` is also viable but more steps.

**Migration steps (chosen option — blob copy):**
1. `az storage blob copy start --account-name nixcfgtfstate7867 --destination-container tfstate --destination-blob tofu.tfstate --source-uri https://nixcfgtfstate7867.blob.core.windows.net/tfstate/hosts/azure/tofu.tfstate` (or equivalent via portal).
2. Update `tofu/providers.tf` backend `key = "tofu.tfstate"`.
3. `nix run .#tofu-vars && nix run .#tofu-plan` — must report no changes.
4. Keep the old blob in place as a manual rollback reference until stable.

**Alternatives considered:**
- Keep the old key — leaves stale path baked into prod state; rejected.
- `tofu state pull` (with old key) → swap key in `providers.tf` → `tofu state push` (with new key) — works but needs two tofu operations against the same state plus manual handling; more moving parts; rejected in favor of blob copy.

### D5: Rename the flake binding `azureDefaults` → `infraDefaults`

**Why:** the binding name is now misleading — the file it reads represents personal-infra defaults (the tofu stack's source of truth), not specifically the azure host. Renaming is cosmetic but cheap, and it surfaces the framing change in the flake itself.

**Alternatives considered:** keep `azureDefaults` — would perpetuate the old framing in code; rejected.

### D6: Introduce a behavior spec (`tofu-infra`) for the first time

**Why:** tofu has no spec today; this relocation is a natural moment to capture what tofu-infra is contractually responsible for (provision Azure VM, DNS, run nixos-anywhere, store state under a known key). The spec is descriptive of existing behavior — it does not add requirements on top of what's already shipped.

**Alternatives considered:** relocation with no spec — leaves tofu un-spec'd for longer; rejected.

## Risks / Trade-offs

- **State mismatch if the blob copy is skipped** → mitigation: documented as the mandatory first step in `tasks.md`; the clean-plan check (`nix run .#tofu-plan`) is the explicit gate before declaring done. If the check fails, rollback is trivial: revert `providers.tf` to the old key, point tofu back at the original blob (which is preserved), plan again.
- **`git mv` rename not detected for large files** → low risk; the moved files are small (largest is `main.tf` at 164 lines). Git treats them as renames.
- **Hidden `hosts/azure/*.nix` consumers of `./defaults.nix`* → mitigation: `grep -r "hosts/azure/defaults\|\\./defaults.nix" hosts/azure/` is step 1 in `tasks.md` to enumerate all consumers before editing.
- **Stale doc references** → `hosts/azure/README.md` may reference the old `tofu/` path. Mitigation: grep for `hosts/azure/tofu` across the repo and update.
- **Rollback plan** → rollback is `git revert` of the change commit, then `git mv tofu/ hosts/azure/tofu/` and `git mv tofu/defaults.nix hosts/azure/defaults.nix` to undo, and revert `providers.tf` to the old backend key (the old blob is preserved). No flake input bump needed since no inputs change.

## Migration Plan

1. Pre-flight: `az login` (subscription reachable), `nix develop` shell open.
2. `grep` for any path references to `hosts/azure/tofu` and `hosts/azure/defaults.nix` across the repo so all touch points are known.
3. `git mv hosts/azure/tofu tofu`.
4. `git mv hosts/azure/defaults.nix tofu/defaults.nix`.
5. Edit `flake.nix` (import path, `azureDefaults` → `infraDefaults`, `tofuDir` constant).
6. Edit every `hosts/azure/*.nix` consumer of `./defaults.nix` to import `../../tofu/defaults.nix`.
7. Edit `tofu/defaults.nix` header comment.
8. Edit `tofu/variables.tf` header comment.
9. Edit `tofu/providers.tf` backend `key`.
10. Update `hosts/azure/README.md` if it references the old path.
11. Verify: `nix flake check`, `nix eval .#tofuVars --json` (unchanged), `nix run .#tofu-vars` (regenerates `tofu/terraform.tfvars.json`), `nixos-rebuild dry-build --flake .#azure`.
12. State migration: copy the blob from `hosts/azure/tofu.tfstate` to `tofu.tfstate` in Azure storage; preserve the old blob.
13. Verify: `nix run .#tofu-plan` — must show no changes.
14. Commit as a single move+edit commit. (Per repo convention, the user explicitly asks before committing.)

## Open Questions

- None outstanding. The three framing decisions (lift defaults file; rename state key; directory name = `tofu/`) were resolved during explore.
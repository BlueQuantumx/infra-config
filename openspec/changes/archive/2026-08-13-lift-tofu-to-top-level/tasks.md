## 1. Pre-flight: enumerate all touch points

- [x] 1.1 `rg -n "hosts/azure/tofu|hosts/azure/defaults" --type nix --type tf --type md` and screenshot/file the list of every reference to the old paths (flake.nix, hosts/azure/*.nix, tofu/*.tf, hosts/azure/README.md, any docs)
- [x] 1.2 `rg -n "\./defaults.nix" hosts/azure/` to find every NixOS-side consumer of the lifted defaults file
- [x] 1.3 Confirm `az login` works and `az storage account show --name nixcfgtfstate7867` is reachable (needed for the state migration in step 5)

## 2. Relocate files (preserve git history)

- [x] 2.1 `git mv hosts/azure/tofu tofu`
- [x] 2.2 `git mv hosts/azure/defaults.nix tofu/defaults.nix`
- [x] 2.3 `git status --short` — confirm both entries show as renames (`R`) not delete+add

## 3. Update flake wiring

- [x] 3.1 In `flake.nix`, change `import ./hosts/azure/defaults.nix` → `import ./tofu/defaults.nix`
- [x] 3.2 Rename the binding `azureDefaults` → `infraDefaults` and update every reference inside `tofuVars` (about 10 `azureDefaults.<field>` → `infraDefaults.<field>`)
- [x] 3.3 Set `tofuDir = "tofu"` in `tofuApp` (around line 79) and update the path in `tofuVarsApp` (around line 107) from `hosts/azure/tofu` to `tofu`
- [x] 3.4 Update the comments in `flake.nix` that reference `hosts/azure/tofu` (around lines 55-60 and 150-155) to reference `tofu/`
- [x] 3.5 `nix eval .#tofuVars --json | jq` — confirm the JSON value is byte-identical to the pre-move output (same keys, same values)

## 4. Update NixOS-side consumers of the lifted defaults

- [x] 4.1 For each file found in 1.2 (`hosts/azure/configuration.nix` and any other `hosts/azure/*.nix` using `./defaults.nix`), change the import to `../../tofu/defaults.nix`
- [x] 4.2 `nix flake check` — confirm the azure NixOS configuration still evaluates
- [x] 4.3 `nixos-rebuild dry-build --flake .#azure —-override-input nixpkgs nixpkgs` (or the project's standard dry-build command) — confirm no evaluation errors

## 5. Update tofu files to reflect the new location

- [x] 5.1 In `tofu/defaults.nix`, update the header comment ("hosts/azure/tofu" → "tofu/")
- [x] 5.2 In `tofu/variables.tf`, update the header comment that references `hosts/azure/defaults.nix` → `tofu/defaults.nix`
- [x] 5.3 In `tofu/providers.tf`, change the backend `key = "hosts/azure/tofu.tfstate"` → `key = "tofu.tfstate"`
- [x] 5.4 `nix run .#tofu-vars` — confirm it writes `tofu/terraform.tfvars.json` (new path) and prints the new-path message
- [x] 5.5 Update any reference in `hosts/azure/README.md` (if it mentions the old tofu path) to point to `tofu/`

## 6. State migration (one-time blob copy in Azure storage)

- [x] 6.1 Copy the state blob from `hosts/azure/tofu.tfstate` to `tofu.tfstate` inside container `tfstate` of storage account `nixcfgtfstate7867` (use `az storage blob copy start` or the Azure portal). Do NOT delete the old blob.
- [x] 6.2 Verify the new blob exists: `az storage blob show --container-name tfstate --name tofu.tfstate --account-name nixcfgtfstate7867`
- [x] 6.3 `nix run .#tofu-plan` — the plan MUST show "No changes. Infrastructure is up-to-date." If anything else appears, stop and investigate (most likely cause: blob copy didn't include the lock meta or the new key isn't being read; revert `providers.tf` to the old key temporarily to confirm old state still plans clean, then retry migration).

## 7. Final verification

- [x] 7.1 `nix flake check` — clean
- [x] 7.2 `nix eval .#tofuVars --json` — values unchanged
- [x] 7.3 `nix run .#tofu-vars` — writes to the new path with no error
- [x] 7.4 `nix run .#tofu-plan` — no changes (post-migration)
- [x] 7.5 `nixos-rebuild dry-build --flake .#azure` — clean (the azure NixOS config still consumes the lifted defaults via the new import path)
- [x] 7.6 `git status` — only the intended files changed/moved; no stray `hosts/azure/tofu/` or `hosts/azure/defaults.nix` left
- [x] 7.7 Final sweep: `rg -n "hosts/azure/tofu|hosts/azure/defaults"` across the repo — only acceptable remaining hits are git history / openspec change docs (this change's own artifacts)
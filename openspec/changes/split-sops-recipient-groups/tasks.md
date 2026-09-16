## 1. Rewrite recipient groups in `.sops.yaml`

- [x] 1.1 Replace the single broad `creation_rules` entry with per-audience rules: MacBook-scoped (admin key only), raspi-scoped (admin + raspi), azure-scoped (admin + azure), mesh-scoped (admin + raspi + azure), 529-2-scoped (admin + 529-2), and a client-only rule for the OpenTofu `.env` files. Verify with `yq '.sops.age' secrets/<file>` on each encrypted file that the recipient age keys match the intended group.
- [x] 1.2 Remove the `orb` key anchor and keep `raspi`/`azure`/`529-2`; leave `pascal-cloud-01` commented. Verify `grep -n '&orb' .sops.yaml` returns nothing and `grep -c '&raspi\|&azure\|&529-2' .sops.yaml` is non-zero.

## 2. Split `secrets/common.yaml` by audience

- [x] 2.1 Create the MacBook-scoped file containing `github_token`; verify `sops -d --extract '["github_token"]' <file>` succeeds and the key set equals the original `github_token` entry.
- [x] 2.2 Move the raspi-consumed keys (`singbox/subscription_url`, `tailscale/authkey_raspi`, `my-et-network/secret`) into the raspi-scoped and mesh-scoped files; verify the decrypted key set matches the original entries.
- [x] 2.3 Move the azure-consumed keys (`tailscale/authkey_azure`, `tailscale/authkey_mac`, `tailscale/authkey_ios`, `tailscale/authkey_linux_desktop`, `my-et-network/secret`) into the azure-scoped and mesh-scoped files; verify the decrypted key set matches the original entries.
- [x] 2.4 Confirm the moved set plus the retained files covers every original key (no additions, no drops) and then delete `secrets/common.yaml`; verify `grep -rn 'common\.yaml' --include='*.nix' --include='*.md' .` returns nothing outside `openspec/changes/archive`.

## 3. Rename and re-scope the azure file

- [x] 3.1 `git mv secrets/sub-store.yaml secrets/azure.yaml` and run `sops updatekeys secrets/azure.yaml`; verify `yq '.sops.age' secrets/azure.yaml` lists only the admin and azure recipients.

## 4. Add the 529-2-scoped file

- [x] 4.1 Create `secrets/529-2.yaml` encrypted to the admin and 529-2 recipients (add a placeholder key first if sops refuses an empty document) and repoint `hosts/529-2/sops.nix` `defaultSopsFile` at it; verify `nix eval` of the 529-2 sops path and `yq '.sops.age' secrets/529-2.yaml`.

## 5. Repoint all consumers

- [x] 5.1 Update the `tofu-tailnet-secrets` app in `flake.nix` so `authkey_raspi` is written to the raspi-scoped file and the remaining auth keys to the azure-scoped file; verify by inspecting the per-node target selection and that no branch still references `common.yaml`.
- [x] 5.2 Update `home-manager/modules/github-token.nix` `sopsFile` to the MacBook-scoped file; verify `nix build`/eval of `homeConfigurations."luyan@macbook"` succeeds.
- [x] 5.3 Update `hosts/raspi/configuration.nix` (`my-et-network/secret` → mesh file, `tailscale/authkey_raspi` → raspi file) and `hosts/modules/sing-box.nix` (`singbox/subscription_url` → raspi file); verify `nixos-rebuild dry-build --flake .#raspi` evaluates.
- [x] 5.4 Update `hosts/azure/sops.nix` `defaultSopsFile` and `hosts/azure/configuration.nix` (`my-et-network/secret` → mesh file, tailscale auth keys → azure file); verify `nixos-rebuild dry-build --flake .#azure` evaluates.
- [x] 5.5 Update `hosts/pascal-cloud-01/sops.nix` and its `README.md` so the documented pattern is a per-host file rather than a shared file; verify `grep -rn 'shared secrets file\|共享 secrets' hosts/pascal-cloud-01` returns nothing.
- [x] 5.6 Verify no stale references remain: `grep -rn 'common\.yaml\|sub-store\.yaml' --include='*.nix' --include='*.md' --include='*.tf' .` returns nothing outside `openspec/changes/archive`.

## 6. Align main specs and docs

- [x] 6.1 Update main-spec Purpose text that still describes a shared secrets file (e.g. `openspec/specs/host-529-2/spec.md`, `openspec/specs/host-pascal-cloud-01/spec.md`); verify `openspec validate --all` reports no issues.

## 7. End-to-end verification

- [x] 7.1 Run `nix flake check` and confirm all host checks evaluate; verify no evaluation error mentions a missing secrets file.
- [x] 7.2 Run `nixos-rebuild dry-build --flake .#raspi` and `.#azure` and confirm both succeed.
- [x] 7.3 Negative check: from a non-consumer identity, attempt `sops -d` on another host's scoped file and confirm it fails; verify each host's own scoped file decrypts with the admin key.

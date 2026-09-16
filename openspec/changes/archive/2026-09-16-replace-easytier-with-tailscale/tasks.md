## 1. Tailnet OpenTofu stack

- [x] 1.1 Create `tofu/tailnet/` with `providers.tf` (tailscale provider sourced by version, azurerm backend reusing the existing storage with a new state key), a variables file, and the OpenTofu required-version block; verify with `tofu -chdir=tofu/tailnet init -backend=false && tofu -chdir=tofu/tailnet validate`
- [x] 1.2 Add the ACL resource (tag ownership for server/exit/client tags and `autoApprovers` for the exit tag) and the tailnet DNS preference resource; verify `tofu -chdir=tofu/tailnet validate` and that `tofu -chdir=tofu/tailnet plan` proposes only tailnet resources
- [x] 1.3 Add one `tailscale_tailnet_key` per node (`azure`, `raspi`, `mac`) with role tags, pre-authorized and reusable, and expose each as a sensitive output; verify the plan creates exactly three keys and `tofu -chdir=tofu/tailnet output` marks each output sensitive
- [x] 1.4 Register `tofu-tailnet-plan` / `tofu-tailnet-apply` flake apps alongside the existing `tofu-plan` / `tofu-apply`; verify `nix run .#tofu-tailnet-plan` invokes tofu inside `tofu/tailnet`

## 2. Key bridge into sops

- [x] 2.1 Add a `tofu-tailnet-secrets` flake app that reads the three sensitive key outputs and writes them into `secrets/common.yaml` via `sops set`; verify the run leaves an encrypted diff and `sops -d secrets/common.yaml` (not printed to logs) contains the three entries
- [x] 2.2 Declare the three `tailscale/*` secrets under `sops.secrets` on `azure` and `raspi` with `sopsFile = secrets/common.yaml`; verify `nixos-rebuild dry-build` succeeds on both hosts

## 3. NixOS enrollment

- [x] 3.1 On `azure`, enable `services.tailscale` with `authKeyFile` from the sops secret, `useRoutingFeatures = "server"`, and exit advertisement; verify `nixos-rebuild dry-build --flake .#azure`, then after deploy `tailscale status` shows the node advertising an exit node
- [x] 3.2 On `raspi`, enable `services.tailscale` with `authKeyFile`, `useRoutingFeatures = "server"`, and exit advertisement, with no exit-node consumption; verify `nixos-rebuild dry-build --flake .#raspi`, then after deploy that the node advertises an exit and uses none
- [x] 3.3 Confirm the ACL auto-approves both advertised exit nodes (no pending route approval) and that both nodes carry their role tags; verify in the tailnet policy status or provider data source

## 4. Mac sing-box endpoint

- [x] 4.1 In `hosts/azure/substore.nix`, add a token in the Mac template content replaced by `config.sops.placeholder."tailscale/authkey_mac"`; verify the evaluated `services.substore.renderedFilesJson` contains the placeholder token and no plaintext key (`nix eval` on the rendered option)
- [x] 4.2 Update `substore-templates/1.13/mac.json` and `.../1.14/mac.json`: replace the WireGuard mesh endpoint with a userspace `tailscale` endpoint, add the tailnet CIDR route to that endpoint, and remove the EasyTier mesh route; verify `jq empty` on both files and that a diff shows only the intended endpoint/route changes
- [x] 4.3 Deploy the regenerated subscription and confirm the Mac joins the tailnet and reaches a tailnet address; verify the Mac's tailscale state persists across a subscription refresh (no re-login)

## 5. Caddy upstream

- [x] 5.1 Repoint the navidrome virtual host's reverse proxy from `raspi`'s EasyTier address to its tailnet address; verify `nixos-rebuild dry-build --flake .#azure` and, after deploy, that `navi.egrecho47.top` serves through the tailnet

## 6. Optional EasyTier fallback

- [x] 6.1 Restore the EasyTier host module, its registration in `lib/default.nix`, the `easytier` block in `defaults.nix` (with a new `enable` flag, default off) and the `easytier` overlay pin; verify the module files exist and `nix flake check --no-build --all-systems` passes
- [x] 6.2 Gate the EasyTier service and its sops secret on `easytier.enable` in `hosts/{azure,raspi}/configuration.nix`, adding the scoped forwarding-sysctl tie-break; verify with the flag off (service off, secret undeclared, Tailscale on) and on (service on, secret declared, every host evaluates)
- [x] 6.3 Restore the EasyTier tofu variables and make the TCP/UDP NSG rules conditional on a new `enable_easytier` variable, re-adding the values to `tofuVars` in `flake.nix`; verify `nix run .#tofu-plan` removes the EasyTier rules with the flag off and reports no change with it on
- [x] 6.4 Restore the `my-et-network/secret` entry in `secrets/common.yaml` and the `my-et-network` module mention in `openspec/config.yaml`; verify `sops -d secrets/common.yaml` lists the entry and `openspec validate replace-easytier-with-tailscale` passes

## 7. Verification

- [x] 7.1 Run `nix flake check --no-build` and confirm every declared host still evaluates
- [x] 7.2 End-to-end check: `azure`, `raspi`, and the Mac all appear in the tailnet; both servers advertise an exit node while no client uses one; `navi.egrecho47.top` serves over the public path; no EasyTier process or config remains on any host

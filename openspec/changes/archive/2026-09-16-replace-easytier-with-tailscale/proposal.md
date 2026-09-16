## Why

The homelab mesh is EasyTier: a shared symmetric network secret, a public relay that needs three custom inbound NSG ports, and — on the Mac — a hand-rolled WireGuard endpoint embedded in a downloaded sing-box subscription. Tailscale provides the same reachability with per-node tagged credentials, no mandatory inbound ports, and a tailnet policy OpenTofu can own declaratively.

## What Changes

- **New** `tailnet-mesh`: `azure` and `raspi` join as tagged NixOS nodes (`tag:server`, `tag:exit`) and both advertise exit nodes (no consumer opted in by default); the Mac joins as `tag:client` through sing-box's userspace `tailscale` endpoint, with its auth key injected into the sub-store template via a sops placeholder.
- **New** `tailnet-infra`: a separate `tofu/tailnet/` OpenTofu stack (tailscale provider, own `tailnet.tfstate` key) owning ACL/tags, exit-node auto-approval, MagicDNS preference, and per-node tagged auth keys; new flake apps; a `tofu-tailnet-secrets` bridge that syncs minted keys into `secrets/common.yaml`.
- **Retain** the EasyTier mesh as an opt-in fallback: the host module, its flake registration, the `defaults.nix` easytier block, its sops secret, its OpenTofu NSG rules/vars and the `easytier` overlay pin are all preserved, gated behind a single `easytier.enable` flag that defaults to off. Tailscale is the active mesh; EasyTier can be switched back on as a unit.
- Move the Caddy navidrome upstream from raspi's EasyTier address to its tailnet address.
- Swap the Mac template's WireGuard mesh endpoint for the tailscale endpoint and move the mesh route to `100.64.0.0/10` (1.13 and 1.14 templates).

## Capabilities

### New Capabilities

- `tailnet-mesh`: How each host joins the tailnet, node roles/tags, exit-node advertisement and consumption policy, tailnet-name resolution on the Mac, and the Caddy upstream through the tailnet.
- `tailnet-infra`: The OpenTofu tailnet stack — provider credentials, auth-key minting and tagging, ACL/autoApprovers ownership, DNS preference, state isolation, and the tofu→sops secret bridge.

### Modified Capabilities

- `tofu-infra`: The Azure NSG provisions the EasyTier TCP/UDP rules only when the fallback mesh is enabled; the port values remain shared and are always supplied to OpenTofu.

## Impact

- **Hosts**: `azure`, `raspi` (NixOS), `macbook` (via sub-store templates). `orbstack`, `digitalocean`, `pascal-cloud-01` untouched.
- **Secrets**: adds `tailscale/*` entries to `secrets/common.yaml`; `my-et-network/secret` is retained but only decrypted when the fallback is enabled.
- **OpenTofu state**: adds `tofu/tailnet/` with its own state key; the existing `tofu.tfstate` keeps the EasyTier variables and makes the NSG rules conditional.
- **Files**: `hosts/modules/my-et-network*` (retained), `hosts/{azure,raspi}/configuration.nix`, `overlays/default.nix`, `defaults.nix`, `flake.nix`, `tofu/{main,variables}.tf`, `hosts/azure/substore{,-templates/1.13,1.14/mac.json}`, `hosts/azure/README.md`.

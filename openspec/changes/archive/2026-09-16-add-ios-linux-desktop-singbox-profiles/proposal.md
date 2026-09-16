## Why

The sing-box client templates only cover macOS (`mac`) and headless Linux (`linux-headless`), and every remote device would reuse one Tailnet identity. There is no profile for an iPhone or a Linux desktop, so those devices cannot use the shared routing/DNS rules or join the mesh as first-class nodes.

## What Changes

- Add `ios.json` and `linux-desktop.json` sing-box client templates under both `hosts/azure/substore-templates/1.13/` and `hosts/azure/substore-templates/1.14/`.
- Give each new profile its own Tailscale endpoint identity (distinct auth-key placeholder and hostname) instead of sharing the mac key.
- iOS: keep only the `services.api` control surface with its dashboard; drop `clash_api`, process-based routing (`find_process`, `process_name`), and Linux-only inbound options.
- Linux desktop: mirror the same-version `mac` profile's control surface and routing, with its own Tailnet identity.

## Capabilities

### New Capabilities
- `singbox-client-profiles`: the catalog of sing-box client profile templates and the per-platform shape (identities, control surface, routing) of each.

### Modified Capabilities
(none)

## Impact

- Hosts: `azure` (sub-store template host). New targets are an iPhone and a generic Linux desktop, not existing named hosts.
- Secrets: each new profile references a new Tailscale auth-key placeholder; declarations and substitution are wired, but the encrypted key values still need provisioning (see design.md Follow-ups).
- OpenTofu state: unchanged by this change; provisioning the new tailnet nodes is a possible follow-up.
- Files: `hosts/azure/substore-templates/{1.13,1.14}/{ios,linux-desktop}.json`, plus registration and auth-key substitution wiring in `hosts/azure/substore.nix` and `hosts/azure/configuration.nix`.

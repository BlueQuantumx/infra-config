## Context

See proposal.md - Why. The existing set is four templates: `mac.json` and `linux-headless.json` in each of `hosts/azure/substore-templates/1.13/` and `1.14/`. Only the `mac` templates carry a Tailscale `endpoints` entry (tag `ts-ep`), and it reuses a single auth-key placeholder. The `1.14` templates additionally define `services.api`, `http_clients`, and an API dashboard; the `1.13` templates do not.

## Goals / Non-Goals

**Goals:**
- Add `ios` and `linux-desktop` profiles to both maintained template versions.
- Give each new profile an independent Tailscale identity.
- Keep each profile valid for the sing-box version its directory targets.

**Non-Goals:**
- Provisioning or wiring the real Tailscale auth keys (sops/OpenTofu), tailnet ACLs, or the server-side `hosts/modules/sing-box` module.
- Changing the existing `mac` or `linux-headless` templates.

## Decisions

- **Base each new profile on the same-version `mac.json`.** `mac` is the only single-user client template with a Tailscale endpoint and no `auto_redirect`, so it is the closest analog. Alternative: base on `linux-headless` - rejected because its `0.0.0.0` API bind and `auto_redirect` are server-oriented.
- **Identities:** iOS uses hostname `iphone` with placeholder `__TAILSCALE_AUTHKEY_IOS__`; desktop uses hostname `linux-desktop` with `__TAILSCALE_AUTHKEY_LINUX_DESKTOP__`.
- **iOS control surface:** keep `services.api` and its dashboard, drop `experimental.clash_api`; bind the API to localhost. The dashboard needs its `http_clients` companion entry, so iOS keeps that too.
- **iOS routing:** drop `route.find_process` and the `process_name: aria2c` rule (no process visibility in the iOS sandbox); retain every other rule, rule-set, and the DNS block unchanged.
- **Linux desktop:** mirror the same-version `mac` profile exactly except for the Tailscale identity (hostname + placeholder); keep the localhost clash API and no `services.api`, matching `mac`.
- **1.13 iOS control surface (verified fallback):** sing-box `1.13` rejects both `services` (`unknown inbound type: api`) and `http_clients` (`unknown field`), and accepts only `experimental.clash_api`. Per the fallback, `1.13/ios.json` ships with no API control surface and no clash surface; `1.14/ios.json` keeps `services.api` + dashboard + `http_clients`.

## Risks / Trade-offs

- `1.13` schema rejects `services`/`http_clients` (verified with sing-box 1.13.19) → `1.13/ios.json` omits the control surface; `1.14/ios.json` carries it.
- iOS may not support some inherited fields (e.g. `auto_detect_interface`, TUN `address`) → validate on-device before relying on the profile.
- New auth-key placeholders are inert until secrets are wired → profiles will fail to bring up Tailscale; track key provisioning as a follow-up.
- Duplicated profile bodies across versions drift → accept for now; a shared generator is out of scope.

## Migration Plan

Additive files only; no existing template changes. Deploy by rebuilding the `azure` sub-store output. Rollback is `git revert` of the change commit; no state migration involved.

## Follow-ups

- The `__TAILSCALE_AUTHKEY_IOS__` and `__TAILSCALE_AUTHKEY_LINUX_DESKTOP__` placeholders are substituted with sops placeholders, but the underlying keys are not provisioned. Mint `ios` and `linux_desktop` keys in the tailnet OpenTofu stack (`tofu/tailnet` resources + outputs), add them to the `for node in azure raspi mac` loop in `flake.nix`, run `tofu-tailnet-apply` then the `tofu-tailnet-secrets` app, and rebuild. Until then, `azure` activation fails on the missing sops secrets.

## Why

`.sops.yaml` defines a single creation rule that encrypts every file under `secrets/` to every recipient. Any compromised host can therefore decrypt every other host's secrets — a compromised raspi can read the Azure sub-store URLs, the Cloudflare token, and the Mac auth key, and vice versa. The archived github-token change already flagged this as accepted debt.

## What Changes

- Replace the single broad `creation_rules` entry with per-audience rules, so each secrets file is encrypted only to the hosts that consume it.
- Dissolve `secrets/common.yaml` into audience-scoped files: a MacBook-scoped file (`github_token`), additions to the raspi-scoped and azure-scoped files, and a new mesh-scoped file for `my-et-network`.
- Rename the azure-scoped file from `sub-store.yaml` to reflect that it also carries the Tailscale auth keys.
- Add a new empty `529-2`-scoped file and repoint that host's `defaultSopsFile` at it.
- Keep the admin `client` key as a recipient of every group so secrets stay editable from the MacBook; drop the unused `orb` recipient.
- Repoint every `sopsFile` / `defaultSopsFile` / OpenTofu bridge target at the new files.
- Retain currently-dead secret values rather than deleting them; the change only narrows who can read them.

## Capabilities

### New Capabilities
- `sops-recipient-groups`: Per-audience sops recipient groups so each encrypted secrets file is readable only by its consumer hosts plus the admin key.

### Modified Capabilities
- `github-token`: the token is sourced from the MacBook-scoped secrets file.
- `host-529-2`: the host points at its own per-host secrets file instead of a shared one.
- `host-pascal-cloud-01`: the sops contract uses per-host files, not a shared file.
- `tailnet-infra`: the bridge writes minted auth keys into the azure-scoped file.

## Impact

- **Hosts affected**: macbook (home-manager), raspi, azure, 529-2. `orb` loses its (unused) sops recipient; pascal-cloud-01 stays disabled.
- **Secrets**: yes — all five `secrets/` files are re-encrypted under new recipient groups; every file gains/loses recipients. No secret values are added or removed.
- **OpenTofu**: `tofu-tailnet-secrets` writes to the azure-scoped file; the tailnet OAuth env files keep their admin-only group. No tofu state change.

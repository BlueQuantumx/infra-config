## Context

See `proposal.md` — Why. The current `.sops.yaml` has one `creation_rules` entry whose `key_groups` lists every recipient, so every file under `secrets/` is encrypted to every host. The consumers today are:

- `secrets/common.yaml`: raspi (sing-box subscription, tailscale `authkey_raspi`, `my-et-network`), azure (tailscale `authkey_azure`/`authkey_mac`/`authkey_ios`/`authkey_linux_desktop`, `my-et-network`), MacBook admin key (`github_token`, and all tofu env reads).
- `secrets/raspi.yaml`: raspi (wifi, hust-network-login).
- `secrets/sub-store.yaml`: azure (substore config + templates).
- `secrets/cloudflare.env`, `secrets/tailscale.env`: the administration workstation only (OpenTofu provider creds via `.envrc`).

The `tofu-tailnet-secrets` flake app (`flake.nix`) writes all five `authkey_*` outputs into `common.yaml` with `sops set`. Recipients `orb`, `529-2` are declared; `529-2` consumes nothing, `orb` never enables sops.

Constraints:
- The administration key is the MacBook's `~/.ssh/sops`; it is the only writer used by the flake apps and the only interactive editor.
- `sops updatekeys` only re-wraps an existing file's data key to recipients matching the creation rule for that path; it cannot move keys between files.

## Goals / Non-Goals

**Goals:**
- Each secrets file is readable only by its consumer host(s) plus the administration key.
- Keep the administration workstation able to edit every secret and run every secret-writing flake app.
- Preserve every existing secret key and value.

**Non-Goals:**
- Deleting unused secrets (kept deliberately; only their audience narrows).
- Enabling `529-2`/`pascal-cloud-01` consumers or adding a `pascal-cloud-01` recipient.
- Changing the sops-nix module wiring (`sops-common.nix`, per-host `sops.nix` mechanism) or the tofu provider-credential flow.

## Decisions

### 1. Split by audience, not by host or by secret

Group files by the set of hosts that read them, so a file has exactly one `key_groups` entry. This produces: MacBook-scoped (`github_token`), raspi-scoped, azure-scoped, and a mesh-scoped file for the one secret both raspi and azure consume.

*Alternatives considered:* one file per host duplicates shared secrets across ciphertexts; one file per secret multiplies file count with no isolation benefit.

### 2. The administration key stays in every group

Chosen per the explicit decision. It keeps `github_token` editable from the MacBook and keeps `tofu-tailnet-secrets` able to write. The trade-off (MacBook can read raspi/azure secrets) is accepted because the MacBook is the administration device.

*Alternative rejected:* strict per-target files without the admin key — makes host secrets uneditable from the workstation and breaks the auth-key bridge unless run from azure.

### 3. The auth-key bridge targets each key's consumer file

Because the raspi key must not be readable by azure, the app cannot keep writing all keys into one file. The bridge writes `authkey_raspi` into the raspi-scoped file and `authkey_azure`/`authkey_mac`/`authkey_ios`/`authkey_linux_desktop` into the azure-scoped file. The net-scalar key stays in the azure-scoped file because that is where the mobile/desktop sing-box profiles are rendered.

### 4. Rename `sub-store.yaml` to an azure-scoped name

The file now holds substore config *and* the Tailscale keys, so its old name misdescribes its contents. Renaming is a pure path change; consumers update their `sopsFile`/`defaultSopsFile`.

### 5. `529-2` gets an own empty file

Per the chosen option: a `529-2`-scoped file (admin key + that host) and `sops.defaultSopsFile` repointed to it. The host stays isolated and gains a home for future secrets. `pascal-cloud-01` stays commented out; the pattern it documents becomes "per-host file" rather than "shared file".

### 6. Drop `orb`; retain dead secret values

`orb` never enables sops, so it is removed from the rules. Dead values (`tailscale.client_*`, `my-et-network.wg-*`, `hust-network-login.*`) are carried into their new audience files unchanged.

## Risks / Trade-offs

- [Re-encryption can silently drop a key when splitting files] → Decrypt the old file, diff the key set per destination against the original before/after, and run `nix flake check` plus a per-host `sops -d` sanity check.
- [`.sops.yaml` and ciphertext drift out of sync] → Update `creation_rules` first, then re-encrypt/`sops updatekeys`; verify a non-consumer host fails to decrypt.
- [Bridge now writes to two files] → Keep one app and switch the target per node; the app remains idempotent via `sops set`.
- [MacBook admin key still reads host secrets] → Accepted under the chosen policy; documented in the new capability spec.

## Migration Plan

1. Rewrite `creation_rules` for the new groups; keep anchors for raspi/azure/529-2.
2. Decrypt `common.yaml`, create/re-encrypt the MacBook-scoped, raspi-scoped, azure-scoped and mesh-scoped files; move keys; delete `common.yaml`.
3. `sops updatekeys` the renamed azure-scoped file and the retained `raspi.yaml`, `.env` files.
4. Repoint all `sopsFile`/`defaultSopsFile`/bridge/README references; adjust the affected main specs' Purpose wording that referenced a shared file.
5. Verify `nix flake check`, per-host dry-build, and a decrypt-as-wrong-host negative check.
6. Rollback: `git revert` restores the previous encrypted blobs and rules; no OpenTofu state is touched, so no state migration is required.

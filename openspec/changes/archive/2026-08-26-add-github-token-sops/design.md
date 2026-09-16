## Context

The MacBook (`homeConfigurations."luyan@macbook"`) is a standalone home-manager
config managed from the root `flake.nix`. It currently has a GitHub token in the
macOS keyring (from `gh auth login`), which is imperative and not reproducible.

The repo already uses sops-nix, but only on the NixOS hosts (`azure`, `raspi`)
via `sops-nix.nixosModules.sops`. The MacBook's home-manager config does **not**
import any sops-nix module today, so there is no decryption path there yet.

Key constraints discovered:
- The MacBook's sops identity is the SSH key `~/.ssh/sops` (its pubkey is the
  `client` recipient in `.sops.yaml`). `~/.config/sops/age/keys.txt` is empty,
  so decryption must go through that SSH key, not a dedicated age key.
- macOS has no `/etc/ssh/ssh_host_ed25519_key` host key, so the NixOS
  `SOPS_AGE_SSH_PRIVATE_KEY_FILE` workaround does not apply. sops-nix on darwin
  must be pointed at `~/.ssh/sops` via `sops.age.sshKeyPaths`.

## Goals / Non-Goals

**Goals:**
- Provision `GITHUB_TOKEN` as a real shell environment variable on the MacBook.
- Source the token from a sops-encrypted secret (`secrets/common.yaml`).
- Wire sops-nix into the MacBook home-manager config so decryption is declarative.

**Non-Goals:**
- Changing `gh`/`git` credential config (git already uses SSH; gh protocol unchanged).
- Migrating raspi/orb/azure (only the MacBook).
- Removing or altering the existing keyring token.
- Introducing a dedicated age key (`~/.config/sops/age/keys.txt` stays empty).

## Decisions

### 1. Use `sops.age.sshKeyPaths` plus `SOPS_AGE_SSH_PRIVATE_KEY_FILE`
Sops-nix on darwin has no `/etc/ssh/ssh_host_ed25519_key`. Set
`age.sshKeyPaths = [ "/Users/luyan/.ssh/sops" ]` (maps to the `client` recipient
already in `.sops.yaml`, so no `.sops.yaml` key changes are needed).

**Important**: `sops-install-secrets` (the sops library vendored inside
sops-nix) cannot match the `AGE-SECRET-KEY` identity that `age.sshKeyPaths`
derives against an `ssh-ed25519` recipient — it fails with
`0 successful groups required, got 0`. The fix is to additionally inject
`sops.environment.SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/Users/luyan/.ssh/sops"`,
which makes getsops take its native "read the SSH private key directly" path.
`age.sshKeyPaths` is kept only to satisfy sops-nix's key-source assertion.

### 2. Deliver the env var via a sops template + shell `source`, NOT `sessionVariables`
`home.sessionVariables` is evaluated at Nix eval time and can only reference the
decrypted file *path* (`config.sops.placeholder`), not its value. Since sops
decrypts at build/activation time, we use a template that materializes
`GITHUB_TOKEN=...` and source it from the shell:

```nix
sops.templates."github-env".content = ''
  GITHUB_TOKEN=${config.sops.placeholder."github_token"}
'';
```

Then `programs.zsh.initExtra` sources `${config.sops.templates."github-env".path}`
if it exists.

*Alternative considered:* `home.sessionVariables` — rejected because it can only
carry the file path, not the secret value.

### 3. Scoped module instead of polluting shared modules
`zsh.nix` is shared by raspi/orb/macbook, so the GITHUB_TOKEN sourcing must NOT go
there. Add a new macbook-scoped module `home-manager/modules/github-token.nix`,
imported only by `luyan-macbook.nix`. It owns the sops module import
(`inputs.sops-nix.homeManagerModules.sops`), the secret definition, the template,
and the zsh sourcing.

### 4. Secret lives in `secrets/common.yaml` as `github_token`
Matches the user's choice. `sops -e` will encrypt it for all four recipients; only
the MacBook's `client` key is needed to decrypt here. Token scope is public-repo-only.

## Risks / Trade-offs

- [Token visible to all shell child processes on the MacBook] → Mitigation: it is a
  public-repo-only token, and the user explicitly chose the env-var approach.
- [`common.yaml` now exposes the token to orb/raspi/azure ssh keys] → Mitigation:
  repo-only token scope keeps blast radius low; documented in proposal.
- [Decryption fails if `~/.ssh/sops` is unavailable at activation] → Mitigation:
  `age.sshKeyPaths` points at an existing key; verify before `home-manager switch`.
- [Missing `home-manager/modules/sops.nix` referenced by `luyan-orb.nix` is a
  pre-existing broken import] → Out of scope; not touched by this change.

## Migration Plan

- Apply via `home-manager switch --flake .#luyan@macbook`.
- Rollback: `git revert` the change, or restore by removing the `github-token`
  module import from `luyan-macbook.nix`.

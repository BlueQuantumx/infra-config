## Why

The MacBook currently authenticates to GitHub via a token stored imperatively in the macOS keyring (`gh auth status` shows a `gho_` token), outside of Nix. This makes the credential non-declarative, unversioned, and not reproducible across machines. We want `GITHUB_TOKEN` available as a real environment variable on the MacBook, sourced from a sops-encrypted secret rather than a keyring.

## What Changes

- Encrypt a new `github_token` secret into `secrets/common.yaml` (only the MacBook's `client` key needs to decrypt it, but per the existing multi-recipient file it will be encrypted for all recipients).
- Wire `sops-nix`'s home-manager module into the MacBook home config so the secret decrypts at activation time.
- Expose the decrypted token as a `GITHUB_TOKEN` environment variable via a sops template sourced by the user shell (not `home.sessionVariables`, which can only carry the file path).
- Use a public-repo-only token; no git/gh protocol changes.

## Capabilities

### New Capabilities
- `github-token`: Declarative `GITHUB_TOKEN` provisioning on the MacBook via sops-nix, delivered as a shell environment variable.

### Modified Capabilities
- `macbook-darwin`: The MacBook home-manager config gains sops-nix wiring and a `GITHUB_TOKEN` env var.

## Impact

- **Hosts affected**: MacBook (`homeConfigurations."luyan@macbook"` via `home-manager/modules`, and the `luyan-macbook.nix` entrypoint). No NixOS hosts change.
- **Secrets**: Yes — `secrets/common.yaml` gains a `github_token` entry; `~/.config/sops/age/keys.txt` stays empty, decryption goes through `~/.ssh/sops` (`age.sshKeyPaths`).
- **Shell**: `zsh.nix` module sources a sops template so `GITHUB_TOKEN` is exported in interactive shells.
- **OpenTofu state**: Unaffected.

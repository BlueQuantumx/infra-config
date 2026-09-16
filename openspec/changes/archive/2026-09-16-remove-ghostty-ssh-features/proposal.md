## Why

The Ghostty terminal config enables the `ssh-env` and `ssh-terminfo` shell-integration features, which inject SSH environment/terminfo handling into the shell. This behavior is no longer wanted, and Ghostty 1.3.1 already disables both by default, so the override only re-enables something the user wants gone.

## What Changes

- Remove the `shell-integration-features = "ssh-env,ssh-terminfo";` setting from the Ghostty home-manager module.
- Terminal restores Ghostty's built-in `shell-integration-features` defaults (`cursor,no-sudo,title,no-ssh-env,no-ssh-terminfo,path`), so SSH integration stays off while cursor/title/path integration is re-enabled.
- No other Ghostty settings change.

## Assumptions

- "SSH-related plugin" is interpreted as the SSH shell-integration features (`ssh-env`, `ssh-terminfo`); these are the only SSH-related entries in the Ghostty config.
- Removing the whole line is acceptable; as a side effect Ghostty's default `cursor`, `title`, and `path` shell-integration features become active again.

## Capabilities

### New Capabilities

- `ghostty`: Contract for the MacBook's Ghostty terminal home-manager module, starting with the requirement that SSH shell-integration features remain disabled.

### Modified Capabilities

- (none)

## Impact

- Affected hosts: macbook only (via `home-manager/modules/ghostty.nix`, consumed by `homeConfigurations."luyan@macbook"`). Other hosts and home configs unchanged.
- No secrets and no OpenTofu state involved.
- Rollback: revert the single-line deletion via `git revert`.

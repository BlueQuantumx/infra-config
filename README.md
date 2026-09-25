# infra-config

Personal Nix flake for dotfiles and homelab infra: NixOS / nix-darwin /
home-manager hosts, OpenTofu infrastructure, sops-nix secrets.

## Handling secrets

Values encrypted under `secrets/` must never reach a terminal, a log, a commit
message, or an agent transcript. Every command here is recorded, and a recorded
value is a disclosed value. `openspec/config.yaml` states the rule
("Never let the secrets appear in context(prompt)!"); the post-mortem below is
how it gets broken in practice.

### Incident 2026-09-25: `pascal_ddns_auth` disclosed

Wiring sing-box onto `pascal-cloud`, a probe ran

```sh
sops decrypt /tmp/sops-probe.yaml | tail -1
```

to confirm that `sops set` had preserved the file's recipients. The intent was to
print the trailing `sops:` metadata block, but the decrypted document's last line
was `pascal_ddns_auth: <value>`, so the live Pascal DDNS `report_uuid` — the
bearer token that authorises address reports for that entry — was printed into
the session transcript. Until it is rotated on the DDNS service, treat the token
as live and compromised.

Root cause: a **whole decrypted document** was piped into a command that prints.
The earlier checks in that session had only ever touched ciphertext (the
encrypted file itself), so the rule was being applied per command — "this one is
fine" — instead of to *every* command that touches decrypted bytes. What decides
whether a secret leaks is the last stage of the pipeline, not the intent of the
first one.

### Rules

1. **Decrypt the smallest possible unit, into a consumer that cannot print it** —
   a shell variable, a digest, a comparison, or another `sops` invocation.
2. **Inspect structure from the encrypted file.** `sops` leaves key names,
   the `recipients` list and the metadata block in plaintext, so key existence
   and audience are answerable without decrypting anything:

   ```sh
   sed -E 's/ENC\[[^]]*\]/<ciphertext>/g' secrets/<host>.yaml
   ```

   (The multi-line `age:` blocks are the encrypted data key, not values, and are
   safe to display — as are the `ENC[...]` blobs themselves, which is why they
   live in git; masking them just keeps the view readable.) In particular,
   checking that `sops set` / `sops updatekeys` preserved the recipient list or
   the metadata block never needs a decryption — that is what the command above
   does, and decrypting for it is what caused the incident below.
3. **Never** pipe a decrypted stream into `cat`, `head`, `tail`, `grep`, `yq`,
   `jq -r`, or anything that can print it, and never run them under `set -x` or
   `--verbose`. If a command must consume such a stream, end the pipeline
   somewhere silent: `> /dev/null`, a digest, `cmp`, or a boolean.
4. **Compare values by digest, never by printing**:

   ```sh
   EX='["some"]["key"]'
   a=$(sops decrypt --extract "$EX" a.yaml | shasum -a 256 | cut -c1-16)
   b=$(sops decrypt --extract "$EX" b.yaml | shasum -a 256 | cut -c1-16)
   [ "$a" = "$b" ] && echo match || echo MISMATCH
   ```

5. **Move a value with pipes only, never on a command line.** `sops` provides
   `--value-stdin` / `--value-file` so the value stays out of `ps` output:

   ```sh
   sops decrypt --extract '["some"]["key"]' from.yaml \
     | jq -Rs 'sub("\n$"; "")' \
     | sops set --value-stdin to.yaml '["some"]["key"]'
   ```

6. **Never leave a decrypted copy on disk** (`sops -d f > /tmp/x`,
   abandoned `sops exec-file` working copies). A plaintext file is a disclosure
   waiting for the next command that reads it.
7. **A disclosed value is compromised: rotate it first**, then continue. Do not
   assume the transcript, scrollback, shell history or `/tmp` are private.

### Rotation

```sh
sops set secrets/<host>.yaml '["<key>"]' '"<new value>"'   # value never on screen
```

then update whatever issues the value (for the DDNS entry, its `report_uuid` on
the service) and `nixos-rebuild switch` the host that reads it.

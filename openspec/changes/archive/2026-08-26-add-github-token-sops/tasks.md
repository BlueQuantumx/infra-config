## 1. Encrypt the secret

- [x] 1.1 Add `github_token` to `secrets/common.yaml` with the public-repo-only token value via `sops -e -i secrets/common.yaml`

## 2. Create the macbook-scoped home-manager module

- [x] 2.1 Create `home-manager/modules/github-token.nix` importing `inputs.sops-nix.homeManagerModules.sops` and setting `sops.age.sshKeyPaths = [ "/Users/luyan/.ssh/sops" ]`
- [x] 2.2 Define `sops.secrets."github_token"` with `sopsFile = ../../secrets/common.yaml` and `key = "github_token"`
- [x] 2.3 Define `sops.templates."github-env"` with `content = 'GITHUB_TOKEN=${config.sops.placeholder."github_token"}'`
- [x] 2.4 Add `programs.zsh.initExtra` sourcing `${config.sops.templates."github-env".path}` when the file exists

## 3. Wire module into the MacBook home config

- [x] 3.1 Import `modules/github-token` in `home-manager/luyan-macbook.nix`

## 4. Verify

- [x] 4.1 Run `nix flake check` to confirm eval succeeds for `homeConfigurations."luyan@macbook"` and other hosts stay green
- [x] 4.2 Run `home-manager switch --flake .#luyan@macbook` and confirm `GITHUB_TOKEN` is exported in a new shell

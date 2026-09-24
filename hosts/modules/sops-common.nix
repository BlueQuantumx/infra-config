# sops-nix workaround shared by every host that decrypts secrets:
# https://github.com/Mic92/sops-nix/issues/824
# Each host still declares its own `sops.defaultSopsFile`.
{
  inputs,
  pkgs,
  ...
}:
{
  sops.environment.SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/etc/ssh/ssh_host_ed25519_key";

  # sops-nix builds sops-install-secrets from source, and it is not in nixpkgs,
  # so no binary cache has it: every host compiles it itself. Pascal Cloud hosts
  # cannot reach proxy.golang.org, but goproxy.cn is reachable there, so send
  # the Go module fetch through the CN mirror.
  #
  # This has to go through `sops.package`, not an overlay: the module's default
  # is `(pkgs.callPackage ../.. { }).sops-install-secrets`
  # (modules/sops/default.nix), which constructs the package directly and never
  # consults `pkgs.sops-install-secrets` -- an overlay on that attribute is
  # simply never applied. `buildGoModule` hands the derivation's `env` to the
  # `go-modules` fixed-output derivation that does the fetching
  # (pkgs/build-support/go/module.nix), so GOPROXY here is what the fetch sees.
  # Harmless elsewhere as long as goproxy.cn stays reachable.
  sops.package = (pkgs.callPackage "${inputs.sops-nix}" { }).sops-install-secrets.overrideAttrs (old: {
    env = (old.env or { }) // {
      GOPROXY = "https://goproxy.cn,direct";
    };
  });
}

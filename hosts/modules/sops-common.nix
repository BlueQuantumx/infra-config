# sops-nix workaround shared by every host that decrypts secrets:
# https://github.com/Mic92/sops-nix/issues/824
# Each host still declares its own `sops.defaultSopsFile`.
{
  sops.environment.SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/etc/ssh/ssh_host_ed25519_key";
}

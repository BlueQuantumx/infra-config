# sops wiring for "529-2".
#
# The host has its own secrets file, encrypted to the admin key and this host's
# SSH host key only; no concrete secret is referenced yet. Declare per-host
# secrets here as they appear. The file currently holds only a reserved
# placeholder because sops cannot encrypt an empty document.
{
  sops.defaultSopsFile = ../../secrets/529-2.yaml;
}

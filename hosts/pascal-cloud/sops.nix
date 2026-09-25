{
  sops.defaultSopsFile = ../../secrets/pascal-cloud.yaml;

  # `report_uuid` of this host's entry on the Pascal DDNS service.
  sops.secrets."pascal_ddns_auth" = { };

  # Subscription URL of the sing-box client; the same subscription the other
  # hosts run (the value lives in this host's default sops file).
  sops.secrets."singbox/subscription_url" = { };
}

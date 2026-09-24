{
  sops.defaultSopsFile = ../../secrets/pascal-cloud.yaml;

  # `report_uuid` of this host's entry on the Pascal DDNS service.
  sops.secrets."pascal_ddns_auth" = { };
}

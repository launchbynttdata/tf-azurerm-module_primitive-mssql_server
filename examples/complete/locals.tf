locals {
  resource_group_name   = module.resource_names["resource_group"].minimal_random_suffix
  mssql_server_name     = module.resource_names["mssql_server"].dns_compliant_minimal_random_suffix
  vnet_name             = module.resource_names["vnet"].standard
  private_endpoint_name = module.resource_names["private_endpoint"].standard
  private_dns_link_name = module.resource_names["private_dns_vnet_link"].standard
}

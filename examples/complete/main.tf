// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module "resource_names" {
  source  = "terraform.registry.launch.nttdata.com/module_library/resource_name/launch"
  version = "~> 2.4"

  for_each = var.resource_names_map

  logical_product_family  = var.logical_product_family
  logical_product_service = var.logical_product_service
  region                  = var.location
  class_env               = var.class_env
  cloud_resource_type     = each.value.name
  instance_env            = var.instance_env
  instance_resource       = var.instance_resource
  maximum_length          = each.value.max_length
}

module "resource_group" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/resource_group/azurerm"
  version = "~> 1.1"

  name     = local.resource_group_name
  location = var.location

  tags = merge(var.tags, { resource_name = module.resource_names["resource_group"].standard })
}

module "vnet" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/virtual_network/azurerm"
  version = "~> 3.2"

  vnet_location        = var.location
  resource_group_name  = module.resource_group.name
  vnet_name            = local.vnet_name
  address_space        = var.address_space
  subnets              = var.subnets
  bgp_community        = null
  ddos_protection_plan = null
  dns_servers          = []

  tags = merge(var.tags, { resource_name = module.resource_names["vnet"].standard })

  depends_on = [module.resource_group]
}

resource "random_password" "administrator" {
  length           = 24
  special          = true
  override_special = "!#%^*()-_=+[]{}"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

module "mssql_server" {
  source = "../.."

  name                         = local.mssql_server_name
  resource_group_name          = module.resource_group.name
  location                     = var.location
  server_version               = var.server_version
  administrator_login          = var.administrator_login
  administrator_login_password = random_password.administrator.result

  azuread_administrator                        = var.azuread_administrator
  connection_policy                            = var.connection_policy
  express_vulnerability_assessment_enabled     = var.express_vulnerability_assessment_enabled
  identity                                     = var.identity
  transparent_data_encryption_key_vault_key_id = var.transparent_data_encryption_key_vault_key_id
  primary_user_assigned_identity_id            = var.primary_user_assigned_identity_id
  minimum_tls_version                          = var.minimum_tls_version
  public_network_access_enabled                = var.public_network_access_enabled
  outbound_network_restriction_enabled         = var.outbound_network_restriction_enabled

  tags = merge(var.tags, { resource_name = local.mssql_server_name })

  depends_on = [module.resource_group]
}

module "private_dns_zone" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/private_dns_zone/azurerm"
  version = "~> 1.1"

  zone_name           = var.private_dns_zone_name
  resource_group_name = module.resource_group.name

  tags = var.tags

  depends_on = [module.resource_group]
}

module "vnet_link" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/private_dns_vnet_link/azurerm"
  version = "~> 2.0"

  link_name             = local.private_dns_link_name
  private_dns_zone_name = module.private_dns_zone.zone_name
  virtual_network_id    = module.vnet.vnet_id
  resource_group_name   = module.resource_group.name
  registration_enabled  = false

  tags = var.tags

  depends_on = [module.private_dns_zone, module.resource_group, module.vnet]
}

module "private_endpoint" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/private_endpoint/azurerm"
  version = "~> 3.0"

  endpoint_name                   = local.private_endpoint_name
  resource_group_name             = module.resource_group.name
  region                          = var.location
  subnet_id                       = module.vnet.subnet_map["private_endpoints"].id
  private_service_connection_name = "${local.private_endpoint_name}-conn"
  private_connection_resource_id  = module.mssql_server.id
  is_manual_connection            = false
  subresource_names               = ["sqlServer"]
  private_dns_zone_ids            = [module.private_dns_zone.id]
  private_dns_zone_group_name     = "mssql-server"

  tags = merge(var.tags, { resource_name = module.resource_names["private_endpoint"].standard })

  depends_on = [module.resource_group, module.vnet, module.mssql_server, module.private_dns_zone]
}

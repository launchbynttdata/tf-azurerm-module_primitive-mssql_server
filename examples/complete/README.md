# Complete Example

Secure-by-default deployment of `azurerm_mssql_server` on an internal-only virtual network with a private endpoint and no public network access.

## Usage

```hcl
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
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7, < 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0, < 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0, < 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mssql_server"></a> [mssql\_server](#module\_mssql\_server) | ../.. | n/a |
| <a name="module_private_dns_zone"></a> [private\_dns\_zone](#module\_private\_dns\_zone) | terraform.registry.launch.nttdata.com/module_primitive/private_dns_zone/azurerm | ~> 1.1 |
| <a name="module_private_endpoint"></a> [private\_endpoint](#module\_private\_endpoint) | terraform.registry.launch.nttdata.com/module_primitive/private_endpoint/azurerm | ~> 3.0 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform.registry.launch.nttdata.com/module_primitive/resource_group/azurerm | ~> 1.1 |
| <a name="module_resource_names"></a> [resource\_names](#module\_resource\_names) | terraform.registry.launch.nttdata.com/module_library/resource_name/launch | ~> 2.4 |
| <a name="module_vnet"></a> [vnet](#module\_vnet) | terraform.registry.launch.nttdata.com/module_primitive/virtual_network/azurerm | ~> 3.2 |
| <a name="module_vnet_link"></a> [vnet\_link](#module\_vnet\_link) | terraform.registry.launch.nttdata.com/module_primitive/private_dns_vnet_link/azurerm | ~> 2.0 |

## Resources

| Name | Type |
|------|------|
| [random_password.administrator](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | Address space for the internal-only virtual network. | `list(string)` | <pre>[<br/>  "10.60.0.0/24"<br/>]</pre> | no |
| <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login) | Administrator login for the SQL Server. | `string` | `"sqladminuser"` | no |
| <a name="input_azuread_administrator"></a> [azuread\_administrator](#input\_azuread\_administrator) | Optional Azure AD administrator block. Defaults to null in the complete example (SQL login authentication). | <pre>object({<br/>    login_username              = string<br/>    object_id                   = string<br/>    tenant_id                   = optional(string)<br/>    azuread_authentication_only = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_class_env"></a> [class\_env](#input\_class\_env) | Environment where resource is going to be deployed. For example: dev, qa, uat. | `string` | `"dev"` | no |
| <a name="input_connection_policy"></a> [connection\_policy](#input\_connection\_policy) | Server connection type. Valid values are Default, Proxy, and Redirect. | `string` | `"Default"` | no |
| <a name="input_express_vulnerability_assessment_enabled"></a> [express\_vulnerability\_assessment\_enabled](#input\_express\_vulnerability\_assessment\_enabled) | Whether Express Vulnerability Assessment is enabled for the SQL Server. | `bool` | `false` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | Optional managed identity configuration. | <pre>object({<br/>    type         = string<br/>    identity_ids = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_instance_env"></a> [instance\_env](#input\_instance\_env) | Number that represents the instance of the environment. | `number` | `0` | no |
| <a name="input_instance_resource"></a> [instance\_resource](#input\_instance\_resource) | Number that represents the instance of the resource. | `number` | `0` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created. | `string` | `"eastus2"` | no |
| <a name="input_logical_product_family"></a> [logical\_product\_family](#input\_logical\_product\_family) | Name of the product family for which the resource is created. | `string` | `"launch"` | no |
| <a name="input_logical_product_service"></a> [logical\_product\_service](#input\_logical\_product\_service) | Name of the product service for which the resource is created. | `string` | `"mssql"` | no |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | Minimum TLS version for the SQL Server. | `string` | `"1.2"` | no |
| <a name="input_outbound_network_restriction_enabled"></a> [outbound\_network\_restriction\_enabled](#input\_outbound\_network\_restriction\_enabled) | Whether outbound network traffic is restricted for this SQL Server. | `bool` | `true` | no |
| <a name="input_primary_user_assigned_identity_id"></a> [primary\_user\_assigned\_identity\_id](#input\_primary\_user\_assigned\_identity\_id) | Optional primary user-assigned identity ID. | `string` | `null` | no |
| <a name="input_private_dns_zone_name"></a> [private\_dns\_zone\_name](#input\_private\_dns\_zone\_name) | Private DNS zone used for Azure SQL private endpoints. | `string` | `"privatelink.database.windows.net"` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether public network access is allowed for this SQL Server. | `bool` | `false` | no |
| <a name="input_resource_names_map"></a> [resource\_names\_map](#input\_resource\_names\_map) | A map of key to resource\_name that will be used by tf-launch-module\_library-resource\_name to generate resource names | <pre>map(object({<br/>    name       = string<br/>    max_length = optional(number, 60)<br/>  }))</pre> | <pre>{<br/>  "mssql_server": {<br/>    "max_length": 63,<br/>    "name": "mssql"<br/>  },<br/>  "private_dns_vnet_link": {<br/>    "max_length": 60,<br/>    "name": "pdnslink"<br/>  },<br/>  "private_endpoint": {<br/>    "max_length": 60,<br/>    "name": "pe"<br/>  },<br/>  "resource_group": {<br/>    "max_length": 90,<br/>    "name": "rg"<br/>  },<br/>  "vnet": {<br/>    "max_length": 64,<br/>    "name": "vnet"<br/>  }<br/>}</pre> | no |
| <a name="input_server_version"></a> [server\_version](#input\_server\_version) | Version of the SQL Server. Valid values are 2.0 and 12.0. | `string` | `"12.0"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnet map for the internal-only virtual network. No custom routes or public endpoints are attached. | <pre>map(object({<br/>    prefix = string<br/>    delegation = optional(map(object({<br/>      service_name    = string<br/>      service_actions = list(string)<br/>    })), {})<br/>    service_endpoints                             = optional(list(string), [])<br/>    private_endpoint_network_policies_enabled     = optional(bool, false)<br/>    private_link_service_network_policies_enabled = optional(bool, false)<br/>    network_security_group_id                     = optional(string, null)<br/>    route_table_id                                = optional(string, null)<br/>  }))</pre> | <pre>{<br/>  "private_endpoints": {<br/>    "prefix": "10.60.0.0/26",<br/>    "private_endpoint_network_policies_enabled": false<br/>  }<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources. | `map(string)` | <pre>{<br/>  "provisioner": "terraform"<br/>}</pre> | no |
| <a name="input_transparent_data_encryption_key_vault_key_id"></a> [transparent\_data\_encryption\_key\_vault\_key\_id](#input\_transparent\_data\_encryption\_key\_vault\_key\_id) | Optional versioned Key Vault key ID used for Transparent Data Encryption. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_minimum_tls_version"></a> [minimum\_tls\_version](#output\_minimum\_tls\_version) | Minimum TLS version configured on the Microsoft SQL Server. |
| <a name="output_mssql_server_fqdn"></a> [mssql\_server\_fqdn](#output\_mssql\_server\_fqdn) | Fully qualified domain name of the Microsoft SQL Server. |
| <a name="output_mssql_server_id"></a> [mssql\_server\_id](#output\_mssql\_server\_id) | ID of the Microsoft SQL Server created by the example. |
| <a name="output_mssql_server_name"></a> [mssql\_server\_name](#output\_mssql\_server\_name) | Name of the Microsoft SQL Server created by the example. |
| <a name="output_outbound_network_restriction_enabled"></a> [outbound\_network\_restriction\_enabled](#output\_outbound\_network\_restriction\_enabled) | Whether outbound network traffic is restricted for the Microsoft SQL Server. |
| <a name="output_private_dns_zone_name"></a> [private\_dns\_zone\_name](#output\_private\_dns\_zone\_name) | Name of the private DNS zone used for SQL private endpoints. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | ID of the private endpoint attached to the Microsoft SQL Server. |
| <a name="output_public_network_access_enabled"></a> [public\_network\_access\_enabled](#output\_public\_network\_access\_enabled) | Whether public network access is enabled on the Microsoft SQL Server. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group created by the example. |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | ID of the internal-only virtual network. |
<!-- END_TF_DOCS -->

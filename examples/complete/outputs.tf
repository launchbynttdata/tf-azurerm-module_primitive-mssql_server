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

output "resource_group_name" {
  description = "Name of the resource group created by the example."
  value       = module.resource_group.name
}

output "mssql_server_id" {
  description = "ID of the Microsoft SQL Server created by the example."
  value       = module.mssql_server.id
}

output "mssql_server_name" {
  description = "Name of the Microsoft SQL Server created by the example."
  value       = module.mssql_server.name
}

output "mssql_server_fqdn" {
  description = "Fully qualified domain name of the Microsoft SQL Server."
  value       = module.mssql_server.fully_qualified_domain_name
}

output "public_network_access_enabled" {
  description = "Whether public network access is enabled on the Microsoft SQL Server."
  value       = module.mssql_server.public_network_access_enabled
}

output "minimum_tls_version" {
  description = "Minimum TLS version configured on the Microsoft SQL Server."
  value       = module.mssql_server.minimum_tls_version
}

output "vnet_id" {
  description = "ID of the internal-only virtual network."
  value       = module.vnet.vnet_id
}

output "private_endpoint_id" {
  description = "ID of the private endpoint attached to the Microsoft SQL Server."
  value       = module.private_endpoint.id
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone used for SQL private endpoints."
  value       = module.private_dns_zone.zone_name
}

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

output "id" {
  description = "The ID of the Microsoft SQL Server."
  value       = azurerm_mssql_server.mssql_server.id
}

output "name" {
  description = "The name of the Microsoft SQL Server."
  value       = azurerm_mssql_server.mssql_server.name
}

output "fully_qualified_domain_name" {
  description = "The fully qualified domain name of the Microsoft SQL Server."
  value       = azurerm_mssql_server.mssql_server.fully_qualified_domain_name
}

output "restorable_dropped_database_ids" {
  description = "A list of dropped restorable database IDs on the Microsoft SQL Server."
  value       = azurerm_mssql_server.mssql_server.restorable_dropped_database_ids
}

output "identity" {
  description = "Identity block exported by the Microsoft SQL Server."
  value       = azurerm_mssql_server.mssql_server.identity
}

output "public_network_access_enabled" {
  description = "Whether public network access is enabled on the Microsoft SQL Server."
  value       = azurerm_mssql_server.mssql_server.public_network_access_enabled
}

output "minimum_tls_version" {
  description = "Minimum TLS version configured on the Microsoft SQL Server."
  value       = azurerm_mssql_server.mssql_server.minimum_tls_version
}

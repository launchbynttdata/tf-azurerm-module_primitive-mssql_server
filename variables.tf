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

variable "name" {
  description = "Name of the Microsoft SQL Server. Must be globally unique."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the SQL Server."
  type        = string
}

variable "location" {
  description = "Azure region where the SQL Server is deployed."
  type        = string
}

variable "server_version" {
  description = "Version of the SQL Server. Valid values are 2.0 and 12.0."
  type        = string

  validation {
    condition     = contains(["2.0", "12.0"], var.server_version)
    error_message = "server_version must be either 2.0 or 12.0."
  }
}

variable "administrator_login" {
  description = "Administrator login for the SQL Server. Required unless azuread_administrator.azuread_authentication_only is true."
  type        = string
  default     = null
}

variable "administrator_login_password" {
  description = "Administrator password for the SQL Server. Required unless azuread_administrator.azuread_authentication_only is true."
  type        = string
  default     = null
  sensitive   = true
}

variable "azuread_administrator" {
  description = "Optional Azure AD administrator block. When azuread_authentication_only is true, SQL login credentials are not required."
  type = object({
    login_username              = string
    object_id                   = string
    tenant_id                   = optional(string)
    azuread_authentication_only = optional(bool)
  })
  default = null
}

variable "connection_policy" {
  description = "Server connection type. Valid values are Default, Proxy, and Redirect."
  type        = string
  default     = "Default"

  validation {
    condition     = contains(["Default", "Proxy", "Redirect"], var.connection_policy)
    error_message = "connection_policy must be Default, Proxy, or Redirect."
  }
}

variable "express_vulnerability_assessment_enabled" {
  description = "Whether Express Vulnerability Assessment is enabled for the SQL Server."
  type        = bool
  default     = false
}

variable "identity" {
  description = "Optional managed identity configuration. Allowed type values: SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned. UserAssigned requires identity_ids."
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null

  validation {
    condition = var.identity == null || contains([
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned, UserAssigned"
    ], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }

  validation {
    condition = (
      var.identity == null ||
      var.identity.type == "SystemAssigned" ||
      (var.identity.identity_ids != null && length(var.identity.identity_ids) > 0)
    )
    error_message = "identity.identity_ids must be provided when identity.type includes UserAssigned."
  }
}

variable "transparent_data_encryption_key_vault_key_id" {
  description = "Optional versioned Key Vault key ID used for Transparent Data Encryption."
  type        = string
  default     = null
}

variable "primary_user_assigned_identity_id" {
  description = "Optional primary user-assigned identity ID. Required when identity includes UserAssigned."
  type        = string
  default     = null
}

variable "minimum_tls_version" {
  description = "Minimum TLS version for the SQL Server. Valid value is 1.2."
  type        = string
  default     = "1.2"

  validation {
    condition     = var.minimum_tls_version == "1.2"
    error_message = "minimum_tls_version must be 1.2."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this SQL Server."
  type        = bool
  default     = false
}

variable "outbound_network_restriction_enabled" {
  description = "Whether outbound network traffic is restricted for this SQL Server."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the SQL Server."
  type        = map(string)
  default     = {}
}

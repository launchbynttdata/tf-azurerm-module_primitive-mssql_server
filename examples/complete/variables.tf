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

variable "resource_names_map" {
  description = "A map of key to resource_name that will be used by tf-launch-module_library-resource_name to generate resource names"
  type = map(object({
    name       = string
    max_length = optional(number, 60)
  }))

  default = {
    resource_group = {
      name       = "rg"
      max_length = 90
    }
    mssql_server = {
      name       = "mssql"
      max_length = 63
    }
    vnet = {
      name       = "vnet"
      max_length = 64
    }
    private_endpoint = {
      name       = "pe"
      max_length = 60
    }
    private_dns_vnet_link = {
      name       = "pdnslink"
      max_length = 60
    }
  }
}

variable "logical_product_family" {
  type        = string
  description = "Name of the product family for which the resource is created."
  nullable    = false
  default     = "launch"

  validation {
    condition     = can(regex("^[_\\-A-Za-z0-9]+$", var.logical_product_family))
    error_message = "The variable must contain letters, numbers, -, and _."
  }
}

variable "logical_product_service" {
  type        = string
  description = "Name of the product service for which the resource is created."
  nullable    = false
  default     = "mssql"

  validation {
    condition     = can(regex("^[_\\-A-Za-z0-9]+$", var.logical_product_service))
    error_message = "The variable must contain letters, numbers, -, and _."
  }
}

variable "location" {
  type        = string
  description = "Azure region where resources will be created."
  nullable    = false
  default     = "eastus2"
}

variable "class_env" {
  type        = string
  description = "Environment where resource is going to be deployed. For example: dev, qa, uat."
  nullable    = false
  default     = "dev"

  validation {
    condition     = length(regexall("\\b \\b", var.class_env)) == 0
    error_message = "Spaces between the words are not allowed."
  }
}

variable "instance_env" {
  type        = number
  description = "Number that represents the instance of the environment."
  default     = 0

  validation {
    condition     = var.instance_env >= 0 && var.instance_env <= 999
    error_message = "Instance number should be between 0 to 999."
  }
}

variable "instance_resource" {
  type        = number
  description = "Number that represents the instance of the resource."
  default     = 0

  validation {
    condition     = var.instance_resource >= 0 && var.instance_resource <= 100
    error_message = "Instance number should be between 0 to 100."
  }
}

variable "address_space" {
  description = "Address space for the internal-only virtual network."
  type        = list(string)
  default     = ["10.60.0.0/24"]
}

variable "subnets" {
  description = "Subnet map for the internal-only virtual network. No custom routes or public endpoints are attached."
  type = map(object({
    prefix = string
    delegation = optional(map(object({
      service_name    = string
      service_actions = list(string)
    })), {})
    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies_enabled     = optional(bool, false)
    private_link_service_network_policies_enabled = optional(bool, false)
    network_security_group_id                     = optional(string, null)
    route_table_id                                = optional(string, null)
  }))
  default = {
    private_endpoints = {
      prefix                                    = "10.60.0.0/26"
      private_endpoint_network_policies_enabled = false
    }
  }
}

variable "private_dns_zone_name" {
  description = "Private DNS zone used for Azure SQL private endpoints."
  type        = string
  default     = "privatelink.database.windows.net"
}

variable "server_version" {
  description = "Version of the SQL Server. Valid values are 2.0 and 12.0."
  type        = string
  default     = "12.0"
}

variable "administrator_login" {
  description = "Administrator login for the SQL Server."
  type        = string
  default     = "sqladminuser"
}

variable "azuread_administrator" {
  description = "Optional Azure AD administrator block. Defaults to null in the complete example (SQL login authentication)."
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
}

variable "express_vulnerability_assessment_enabled" {
  description = "Whether Express Vulnerability Assessment is enabled for the SQL Server."
  type        = bool
  default     = false
}

variable "identity" {
  description = "Optional managed identity configuration."
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null
}

variable "transparent_data_encryption_key_vault_key_id" {
  description = "Optional versioned Key Vault key ID used for Transparent Data Encryption."
  type        = string
  default     = null
}

variable "primary_user_assigned_identity_id" {
  description = "Optional primary user-assigned identity ID."
  type        = string
  default     = null
}

variable "minimum_tls_version" {
  description = "Minimum TLS version for the SQL Server."
  type        = string
  default     = "1.2"
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this SQL Server."
  type        = bool
  default     = false
}

variable "outbound_network_restriction_enabled" {
  description = "Whether outbound network traffic is restricted for this SQL Server. The complete example defaults to true; the primitive module defaults to false."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default = {
    provisioner = "terraform"
  }
}

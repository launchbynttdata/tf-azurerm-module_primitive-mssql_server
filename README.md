# AzureRM MSSQL Server Primitive

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC_BY--NC--ND_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

## Overview

Terraform primitive module that provisions a single `azurerm_mssql_server` resource. The module exposes production configuration for networking, TLS, identity, and Azure AD administration while keeping architecture-level composition in the calling example.

## Usage

```hcl
module "mssql_server" {
  source = "terraform.registry.launch.nttdata.com/module_primitive/mssql_server/azurerm"

  name                         = "example-mssql-server"
  resource_group_name          = "example-rg"
  location                     = "eastus2"
  server_version               = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = var.administrator_login_password

  minimum_tls_version                  = "1.2"
  public_network_access_enabled        = false
  outbound_network_restriction_enabled = true

  tags = {
    environment = "dev"
  }
}
```

See `examples/complete` for a secure-by-default pattern that places the server on an internal-only virtual network with a private endpoint and a generated administrator password.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_mssql_server.mssql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login) | Administrator login for the SQL Server. Required unless azuread\_administrator.azuread\_authentication\_only is true. | `string` | `null` | no |
| <a name="input_administrator_login_password"></a> [administrator\_login\_password](#input\_administrator\_login\_password) | Administrator password for the SQL Server. Required unless azuread\_administrator.azuread\_authentication\_only is true. | `string` | `null` | no |
| <a name="input_azuread_administrator"></a> [azuread\_administrator](#input\_azuread\_administrator) | Optional Azure AD administrator block. When azuread\_authentication\_only is true, SQL login credentials are not required. | <pre>object({<br/>    login_username              = string<br/>    object_id                   = string<br/>    tenant_id                   = optional(string)<br/>    azuread_authentication_only = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_connection_policy"></a> [connection\_policy](#input\_connection\_policy) | Server connection type. Valid values are Default, Proxy, and Redirect. | `string` | `"Default"` | no |
| <a name="input_express_vulnerability_assessment_enabled"></a> [express\_vulnerability\_assessment\_enabled](#input\_express\_vulnerability\_assessment\_enabled) | Whether Express Vulnerability Assessment is enabled for the SQL Server. | `bool` | `false` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | Optional managed identity configuration. Allowed type values: SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned. | <pre>object({<br/>    type         = string<br/>    identity_ids = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where the SQL Server is deployed. | `string` | n/a | yes |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | Minimum TLS version for the SQL Server. Valid value is 1.2. | `string` | `"1.2"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Microsoft SQL Server. Must be globally unique. | `string` | n/a | yes |
| <a name="input_outbound_network_restriction_enabled"></a> [outbound\_network\_restriction\_enabled](#input\_outbound\_network\_restriction\_enabled) | Whether outbound network traffic is restricted for this SQL Server. | `bool` | `false` | no |
| <a name="input_primary_user_assigned_identity_id"></a> [primary\_user\_assigned\_identity\_id](#input\_primary\_user\_assigned\_identity\_id) | Optional primary user-assigned identity ID. Required when identity includes UserAssigned. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether public network access is allowed for this SQL Server. | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group containing the SQL Server. | `string` | n/a | yes |
| <a name="input_server_version"></a> [server\_version](#input\_server\_version) | Version of the SQL Server. Valid values are 2.0 and 12.0. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the SQL Server. | `map(string)` | `{}` | no |
| <a name="input_transparent_data_encryption_key_vault_key_id"></a> [transparent\_data\_encryption\_key\_vault\_key\_id](#input\_transparent\_data\_encryption\_key\_vault\_key\_id) | Optional versioned Key Vault key ID used for Transparent Data Encryption. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fully_qualified_domain_name"></a> [fully\_qualified\_domain\_name](#output\_fully\_qualified\_domain\_name) | The fully qualified domain name of the Microsoft SQL Server. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the Microsoft SQL Server. |
| <a name="output_identity"></a> [identity](#output\_identity) | Identity block exported by the Microsoft SQL Server. |
| <a name="output_minimum_tls_version"></a> [minimum\_tls\_version](#output\_minimum\_tls\_version) | Minimum TLS version configured on the Microsoft SQL Server. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Microsoft SQL Server. |
| <a name="output_public_network_access_enabled"></a> [public\_network\_access\_enabled](#output\_public\_network\_access\_enabled) | Whether public network access is enabled on the Microsoft SQL Server. |
| <a name="output_restorable_dropped_database_ids"></a> [restorable\_dropped\_database\_ids](#output\_restorable\_dropped\_database\_ids) | A list of dropped restorable database IDs on the Microsoft SQL Server. |
<!-- END_TF_DOCS -->

## Module Development

### Pre-Requisites

The following commands should be available on your system:

- `asdf` or `mise`
- `make`
- `python3` (for pre-commit)

Additionally, your `git` user and email must be configured. Run the `make configure` command from the root of the repository to ensure that you meet these requirements.

### Pre-Commit hooks

The [.pre-commit-config.yaml](.pre-commit-config.yaml) file defines certain `pre-commit` hooks that are relevant to Terraform and Golang, as well as some common linting tasks. These will be configured for you when you run `make configure`.

### Local Validation

You should validate the changes you make to any module locally, prior to pushing your changes in a branch to GitHub.

1. Ensure that you have run `make configure` successfully.

2. Ensure you are signed into the appropriate cloud provider (e.g. AWS or Azure) for the module under test in your current console session.

3. Run the Terraform and Golang linters with the following command:

```
make lint
```

4. Once you have satisfied the linters, the following command will build example infrastructure in your configured cloud, run the tests, and then tear down the infrastructure it created:

```
make test
```

The pre-commit validations, as well as the `make lint` and `make test` targets, will all be performed in CI. Running these validations locally prior to opening a PR helps ensure a smooth review and merge process.

### Review & Merge Process

Once your change has been tested locally and your branch pushed up, open a new Pull Request for your branch to the default (main) branch of this repository.

The title of your Pull Request will determine the version bump for this change, and the title must be in [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) format in order to merge. A breaking change will trigger a major version bump, a feature will trigger a minor version bump, and all other types will trigger a patch version bump.

Ensure your CI workflows are passing; seek approval from teammates and address any feedback; seek any explicit approvals required by the CODEOWNERS file. You may merge the PR as soon as all requirements are met, and a new release and tag will be automatically created for you.

### Automatic Updates

The shared configuration and workflow files in this repository are largely managed through the [launch-terraform-skeleton](https://github.com/launchbynttdata/launch-terraform-skeleton) repository. Outside of perhaps the `.gitignore` to account for specific files being generated by certain Terraform modules (e.g. Lambda functions), there should not be much cause to update these files on a per-repo basis, and making changes to them individually is discouraged.

If desired, you can check for and run these updates locally in a branch if you have the `copier` tool installed. Some example commands are included below:

```
# Check for updates, optionally checking prerelease versions
copier check-update [--prereleases]

# Run an update, using default answers if there are any. We use tasks, which requires --trust to be set.
copier update --defaults --trust [--prereleases]

# Recopy from the source, and --overwrite all templated files in the process
copier recopy --defaults --trust --overwrite [--prereleases]
```

Automatic updates will run through a scheduled workflow, and if the post-update tests are successful, the Pull Request created will automatically merge. Conflicts in the update or failures to test may leave a Pull Request outstanding, which needs to be addressed by a Launch Engineer.

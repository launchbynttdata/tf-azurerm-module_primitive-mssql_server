location                                 = "eastus2"
server_version                           = "12.0"
administrator_login                      = "sqladminuser"
public_network_access_enabled            = false
outbound_network_restriction_enabled     = true
minimum_tls_version                      = "1.2"
connection_policy                        = "Default"
express_vulnerability_assessment_enabled = false

address_space = ["10.60.0.0/24"]

subnets = {
  private_endpoints = {
    prefix                                    = "10.60.0.0/26"
    private_endpoint_network_policies_enabled = false
  }
}

tags = {
  provisioner = "terraform"
  purpose     = "terratest"
}

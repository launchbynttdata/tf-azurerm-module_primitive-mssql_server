package testimpl

import (
	"os"
	"strconv"
	"strings"
	"testing"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/sql/armsql"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Known secure values from examples/complete/test.tfvars. Asserted against ARM so
// a tfvars drift that weakens security fails even when Terraform outputs still match.
const (
	expectedPublicNetworkAccessEnabled        = false
	expectedMinimumTLSVersion                 = "1.2"
	expectedOutboundNetworkRestrictionEnabled = true
)

// TestComposableMssqlServer verifies the SQL server and performs an additional
// list operation that is not part of the readonly path.
func TestComposableMssqlServer(t *testing.T, testCtx types.TestContext) {
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionID, "ARM_SUBSCRIPTION_ID environment variable is not set")

	cred, err := azidentity.NewDefaultAzureCredential(nil)
	require.NoError(t, err, "unable to get Azure credentials")

	t.Run("TestMssqlServerSecuritySettings", func(t *testing.T) {
		checkMssqlServerSecuritySettings(t, testCtx, subscriptionID, cred)
	})

	t.Run("TestMssqlServerListedInResourceGroup", func(t *testing.T) {
		checkMssqlServerListedInResourceGroup(t, testCtx, subscriptionID, cred)
	})
}

// TestComposableMssqlServerReadOnly verifies the SQL server using read operations only.
func TestComposableMssqlServerReadOnly(t *testing.T, testCtx types.TestContext) {
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionID, "ARM_SUBSCRIPTION_ID environment variable is not set")

	cred, err := azidentity.NewDefaultAzureCredential(nil)
	require.NoError(t, err, "unable to get Azure credentials")

	t.Run("TestMssqlServerSecuritySettings", func(t *testing.T) {
		checkMssqlServerSecuritySettings(t, testCtx, subscriptionID, cred)
	})
}

func checkMssqlServerSecuritySettings(t *testing.T, testCtx types.TestContext, subscriptionID string, cred *azidentity.DefaultAzureCredential) {
	client := newServersClient(t, subscriptionID, cred)
	tfOpts := testCtx.TerratestTerraformOptions()
	ctx := t.Context()

	resourceGroupName := terraform.OutputContext(t, ctx, tfOpts, "resource_group_name")
	serverName := terraform.OutputContext(t, ctx, tfOpts, "mssql_server_name")
	expectedID := terraform.OutputContext(t, ctx, tfOpts, "mssql_server_id")
	expectedFQDN := terraform.OutputContext(t, ctx, tfOpts, "mssql_server_fqdn")
	publicAccessOutput := terraform.OutputContext(t, ctx, tfOpts, "public_network_access_enabled")
	tlsOutput := terraform.OutputContext(t, ctx, tfOpts, "minimum_tls_version")
	outboundRestrictionOutput := terraform.OutputContext(t, ctx, tfOpts, "outbound_network_restriction_enabled")

	require.NotEmpty(t, publicAccessOutput, "public_network_access_enabled output must not be empty")
	publicAccessEnabled, err := strconv.ParseBool(publicAccessOutput)
	require.NoError(t, err, "public_network_access_enabled output must be a boolean string")
	require.Equal(t, expectedPublicNetworkAccessEnabled, publicAccessEnabled, "public_network_access_enabled output must match the complete example contract")

	require.NotEmpty(t, tlsOutput, "minimum_tls_version output must not be empty")
	require.Equal(t, expectedMinimumTLSVersion, tlsOutput, "minimum_tls_version output must match the complete example contract")

	require.NotEmpty(t, outboundRestrictionOutput, "outbound_network_restriction_enabled output must not be empty")
	outboundRestrictionEnabled, err := strconv.ParseBool(outboundRestrictionOutput)
	require.NoError(t, err, "outbound_network_restriction_enabled output must be a boolean string")
	require.Equal(t, expectedOutboundNetworkRestrictionEnabled, outboundRestrictionEnabled, "outbound_network_restriction_enabled output must match the complete example contract")

	server, err := client.Get(ctx, resourceGroupName, serverName, nil)
	require.NoError(t, err, "failed to get Microsoft SQL Server")

	require.NotNil(t, server.ID, "SQL Server ID must be returned")
	assert.Equal(t, strings.ToLower(expectedID), strings.ToLower(*server.ID), "SQL Server ID does not match")

	require.NotNil(t, server.Properties, "SQL Server properties must be returned")
	require.NotNil(t, server.Properties.FullyQualifiedDomainName, "SQL Server FQDN must be returned")
	assert.Equal(t, strings.ToLower(expectedFQDN), strings.ToLower(*server.Properties.FullyQualifiedDomainName), "SQL Server FQDN does not match")

	require.NotNil(t, server.Properties.PublicNetworkAccess, "SQL Server publicNetworkAccess must be returned")
	require.Equal(t, armsql.ServerNetworkAccessFlagDisabled, *server.Properties.PublicNetworkAccess, "SQL Server public network access must be Disabled")

	require.NotNil(t, server.Properties.MinimalTLSVersion, "SQL Server minimalTlsVersion must be returned")
	require.Equal(t, expectedMinimumTLSVersion, *server.Properties.MinimalTLSVersion, "SQL Server minimum TLS version must be 1.2")

	require.NotNil(t, server.Properties.RestrictOutboundNetworkAccess, "SQL Server restrictOutboundNetworkAccess must be returned")
	require.Equal(t, armsql.ServerNetworkAccessFlagEnabled, *server.Properties.RestrictOutboundNetworkAccess, "SQL Server outbound network restriction must be Enabled")

	require.NotNil(t, server.Tags, "SQL Server tags must be returned")
	provisionerTag, ok := server.Tags["provisioner"]
	require.True(t, ok, "SQL Server tags must include provisioner")
	require.NotNil(t, provisionerTag, "SQL Server provisioner tag must have a value")
	assert.Equal(t, "terraform", strings.ToLower(*provisionerTag), "SQL Server provisioner tag does not match")

	resourceNameTag, ok := server.Tags["resource_name"]
	require.True(t, ok, "SQL Server tags must include resource_name")
	require.NotNil(t, resourceNameTag, "SQL Server resource_name tag must have a value")
	assert.Equal(t, serverName, *resourceNameTag, "SQL Server resource_name tag does not match")
}

func checkMssqlServerListedInResourceGroup(t *testing.T, testCtx types.TestContext, subscriptionID string, cred *azidentity.DefaultAzureCredential) {
	client := newServersClient(t, subscriptionID, cred)
	tfOpts := testCtx.TerratestTerraformOptions()
	ctx := t.Context()

	resourceGroupName := terraform.OutputContext(t, ctx, tfOpts, "resource_group_name")
	serverName := terraform.OutputContext(t, ctx, tfOpts, "mssql_server_name")

	pager := client.NewListByResourceGroupPager(resourceGroupName, nil)
	found := false

	for pager.More() {
		page, err := pager.NextPage(ctx)
		require.NoError(t, err, "failed to list Microsoft SQL Servers in resource group")

		for _, server := range page.Value {
			if server.Name != nil && strings.EqualFold(*server.Name, serverName) {
				found = true
				break
			}
		}

		if found {
			break
		}
	}

	assert.True(t, found, "Microsoft SQL Server was not found in resource group list")
}

func newServersClient(t *testing.T, subscriptionID string, cred *azidentity.DefaultAzureCredential) *armsql.ServersClient {
	client, err := armsql.NewServersClient(subscriptionID, cred, nil)
	require.NoError(t, err, "failed to create Microsoft SQL Servers client")
	return client
}

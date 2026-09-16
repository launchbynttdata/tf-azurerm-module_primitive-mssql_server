package testimpl

import (
	"os"
	"strings"
	"testing"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/sql/armsql"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
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
	expectedPublicAccess := terraform.OutputContext(t, ctx, tfOpts, "public_network_access_enabled")
	expectedTLS := terraform.OutputContext(t, ctx, tfOpts, "minimum_tls_version")

	server, err := client.Get(ctx, resourceGroupName, serverName, nil)
	require.NoError(t, err, "failed to get Microsoft SQL Server")

	require.NotNil(t, server.ID, "SQL Server ID must be returned")
	assert.Equal(t, strings.ToLower(expectedID), strings.ToLower(*server.ID), "SQL Server ID does not match")

	require.NotNil(t, server.Properties, "SQL Server properties must be returned")
	require.NotNil(t, server.Properties.FullyQualifiedDomainName, "SQL Server FQDN must be returned")
	assert.Equal(t, strings.ToLower(expectedFQDN), strings.ToLower(*server.Properties.FullyQualifiedDomainName), "SQL Server FQDN does not match")

	require.NotNil(t, server.Properties.PublicNetworkAccess, "SQL Server publicNetworkAccess must be returned")
	expectedPublicAccessFlag := armsql.ServerNetworkAccessFlagDisabled
	if expectedPublicAccess == "true" {
		expectedPublicAccessFlag = armsql.ServerNetworkAccessFlagEnabled
	}
	assert.Equal(t, expectedPublicAccessFlag, *server.Properties.PublicNetworkAccess, "SQL Server public network access does not match")

	require.NotNil(t, server.Properties.MinimalTLSVersion, "SQL Server minimalTlsVersion must be returned")
	assert.Equal(t, expectedTLS, *server.Properties.MinimalTLSVersion, "SQL Server minimum TLS version does not match")

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

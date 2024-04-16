@description('The name of the App Service Plan to create')
param appServicePlanName string

@description('The name of the Web App to create')
param webAppName string

@description('The Azure region to create the resources in')
param location string

@description('The SKU of the App Service Plan to create')
@allowed(['S1', 'S2', 'S3', 'P1v3', 'P2v3', 'P3v3', 'P1mv3', 'P2mv3', 'P3mv3'])
param appServicePlanSku string

@description('Whether to enable zone redundancy for the App Service Plan')
param enableZoneRedundancy bool = false

@description('The ID of the VNet to integrate the Web App with')
param vnetResourceId string

@description('The ID of the subnet that will receive web traffic via private endpoint')
param webAppPrivateLinkSubnetId string

@description('The ID of the subnet to use for outbound traffic from the web app to vnet.  Note this cannot be the same subnet as `webAppPrivateLinkSubnetId`')
param webAppVnetIntegrationSubnetId string

@description('The ID of the Log Analytics workspace to send diagnostics to')
param logAnalyticsWorkspaceId string

@description('The name of the Key Vault that contains App Insights and other connection strings, used for key Vault references')
param keyVaultName string

@description('The URI of the Key Vault secret that contains the App Insights connection string')
param appInsightsConnectionStringSecretUri string

@description('The URI of the Key Vault secret that contains the App Configuration connection string')
param appConfigurationConnectionStringSecretUri string

@description('The build ID to append to the deployment names')
param buildId string

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

var appServicePlanDeploymentName = '${appServicePlanName}-${buildId}'
var webAppDeploymentName = '${webAppName}-${buildId}'

var dnsZoneName = 'privatelink.azurewebsites.net'
var dnsZoneDeploymentName = '${dnsZoneName}-${buildId}'

var peName = '${webAppName}-pe'
var peDeploymentName = '${peName}-${buildId}'

var uamiName = '${webAppName}-uami'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

module asp './appServicePlan.bicep' = {
  name: appServicePlanDeploymentName
  params: {
    location: location
    appServicePlanName: appServicePlanName
    skuName: appServicePlanSku
    zoneRedundant: enableZoneRedundancy
  }
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
}

resource kvSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: keyVaultSecretsUserRoleId
}

resource ra 'Microsoft.Authorization/roleAssignments@2022-04-01'= {
  name: guid(kv.id, uamiName, kvSecretsUserRole.id)
  scope: kv
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: kvSecretsUserRole.id
    principalType: 'ServicePrincipal'
  }
}

module webApp './webApp.bicep' = {
  name: webAppDeploymentName
  params: {
    appServicePlanId: asp.outputs.id
    location: location
    webAppName: webAppName
    vnetIntegrationSubnetId: webAppVnetIntegrationSubnetId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    userAssignedManagedIdentityResourceId: uami.id
    appInsightsConnectionStringSecretUri: appInsightsConnectionStringSecretUri
    appConfigurationConnectionStringSecretUri: appConfigurationConnectionStringSecretUri
  }
}

module webAppDns '../dns/privateDnsZone.bicep' = {
  name: dnsZoneDeploymentName
  params: {
    vnetResourceId: vnetResourceId
    zoneName: dnsZoneName
  }
}

module webAppPe '../privateEndpoint/privateEndpoint.bicep' = {
  name: peDeploymentName
  params: {
    location: location
    dnsZoneId: webAppDns.outputs.id
    groupId: 'sites'
    privateEndpointName: peName
    subnetId: webAppPrivateLinkSubnetId
    targetResourceId: webApp.outputs.id
  }
}

output defaultHostName string = webApp.outputs.defaultHostName

param appServicePlanName string
param webAppName string
param location string
@allowed(['S1', 'S2', 'S3', 'P1v3', 'P2v3', 'P3v3', 'P1mv3', 'P2mv3', 'P3mv3'])
param appServicePlanSku string
param enableZoneRedundancy bool = false
param vnetResourceId string
param webAppPrivateLinkSubnetId string
param webAppVnetIntegrationSubnetId string
param logAnalyticsWorkspaceId string
param keyVaultName string
param appInsightsConnectionStringSecretUri string
param appConfigurationConnectionStringSecretUri string
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
    keyVaultResourceId: kv.id
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

param location string = resourceGroup().location
param workloadName string
param environmentSuffix string
param logAnalyticsWorkspaceName string
param keyVaultName string
param vnetName string
param webSubnetName string
param servicesSubnetName string
param appGatewaySubnetName string
param enableZoneRedundancy bool = false
@allowed(['S1', 'S2', 'S3', 'P1v3', 'P2v3', 'P3v3', 'P1mv3', 'P2mv3', 'P3mv3'])
param appServicePlanSku string
param buildId string = substring(newGuid(), 0, 8)

// Web App
var appServicePlanName = '${workloadName}-${environmentSuffix}-asp'
var webAppName = '${workloadName}-${environmentSuffix}-appsvc'
var webAppDeploymentName = '${webAppName}-private-${buildId}'

resource laws 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup()
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

resource webSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: webSubnetName
  parent: vnet
}

resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: servicesSubnetName
  parent: vnet
}

module webApp './modules/appService/privateWebApp.bicep' = {
  name: webAppDeploymentName
  params: {
    location: location
    appServicePlanName: appServicePlanName
    appServicePlanSku: appServicePlanSku
    buildId: buildId
    webAppName: webAppName
    vnetResourceId: vnet.id
    webAppPrivateLinkSubnetId: servicesSubnet.id
    webAppVnetIntegrationSubnetId: webSubnet.id
    enableZoneRedundancy: enableZoneRedundancy
    logAnalyticsWorkspaceId: laws.id
    keyVaultResourceId: kv.id
  }
}

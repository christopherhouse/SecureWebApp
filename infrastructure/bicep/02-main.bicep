param location string = resourceGroup().location
param workloadName string
param environmentSuffix string
param logAnalyticsWorkspaceName string
param keyVaultName string
param vnetName string
param webInboundSubnetName string
param webOutboundSubnetName string
param servicesSubnetName string
param appGatewaySubnetName string
param enableZoneRedundancy bool = false
@allowed(['S1', 'S2', 'S3', 'P1v3', 'P2v3', 'P3v3', 'P1mv3', 'P2mv3', 'P3mv3'])
param appServicePlanSku string
param buildId string = substring(newGuid(), 0, 8)

// App Insights
var appInsightsName = '${workloadName}-${environmentSuffix}-ai'
var appInsightsDeploymentName = '${appInsightsName}-${buildId}'

// Web App
var appServicePlanName = '${workloadName}-${environmentSuffix}-asp'
var webAppName = '${workloadName}-${environmentSuffix}-appsvc'
var webAppDeploymentName = '${webAppName}-private-${buildId}'

// App Configuration
var appConfigName = '${workloadName}-${environmentSuffix}-appconfig'
var appConfigDeploymentName = '${appConfigName}-${buildId}'

// Storage
var baseStorageAccountName = '${workloadName}${environmentSuffix}'
var shortStorageAccountName = length(baseStorageAccountName) > 22 ? substring(baseStorageAccountName, 0, 22) : baseStorageAccountName
var storageAccountName = toLower('${shortStorageAccountName}sa')
var storageAccountDeploymentName = '${storageAccountName}-${buildId}'

// App Gateway
var appGatewayName = '${workloadName}-${environmentSuffix}-appgw'
var appGatewayDeploymentName = '${appGatewayName}-${buildId}'

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

resource webInboundSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: webInboundSubnetName
  parent: vnet
}

resource webOutboundSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: webOutboundSubnetName
  parent: vnet
}

resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: servicesSubnetName
  parent: vnet
}

resource appGwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: appGatewaySubnetName
  parent: vnet
}

module appInsights './modules/applicationInsights/applicationInsights.bicep' = {
  name: appInsightsDeploymentName
  params: {
    location: location
    appInsightsName: appInsightsName
    buildId: buildId
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: laws.id
  }
}

module appConfig './modules/appConfiguration/configurationStore.bicep' = {
  name: appConfigDeploymentName
  params: {
    location: location
    appConfigName: appConfigName
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: laws.id
    buildId: buildId
    servicesSubnetResourceId: servicesSubnet.id
    vnetResourceId: vnet.id
  }
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
    webAppPrivateLinkSubnetId: webInboundSubnet.id
    webAppVnetIntegrationSubnetId: webOutboundSubnet.id
    enableZoneRedundancy: enableZoneRedundancy
    logAnalyticsWorkspaceId: laws.id
    keyVaultName: keyVaultName
    appInsightsConnectionStringSecretUri: appInsights.outputs.connectionStringSecretUri
    appConfigurationConnectionStringSecretUri: appConfig.outputs.appConfigConnectionStringSecretUri
  }
}

module storage './modules/storage/privateStorageAccount.bicep' = {
  name: storageAccountDeploymentName
  params: {
    location: location
    buildId: buildId
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
    storageConnectionStringSecretName: 'STORAGE'
    subnetId: servicesSubnet.id
    vnetResourceId: vnet.id
    zoneRedundant: enableZoneRedundancy
  }
}

// module appGw './modules/applicationGateway/applicationGateway.bicep' = {
//   name: appGatewayDeploymentName
//   params: {
//     location: location
//     appGatewayName: appGatewayName
//     appGatewaySku: 'Standard_v2'
//     appGatewaySkuCapacity: 1
//     frontEndCertificateKeyVaultSecretName: 'www_chrishou_se'
//     keyVaultName: kv.name
//     logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceName
//     subnetResourceId: appGwSubnet.id
//     webAppBackendHostName: webApp.outputs.defaultHostName
//     webAppFrontEndHostName: 'www.chrishou.se'
//   }
// }

module appGw './modules/applicationGateway/appGw.bicep' = {
  name: appGatewayDeploymentName
  params: {
    location: location
    appGatewayName: appGatewayName
    appGatewaySubnetName: appGatewaySubnetName
    keyVaultName: keyVaultName
    skuCapacity: 3
    skuName: 'Standard_v2'
    vnetName: vnetName
    webAppSslCertKeyVaultSecretName: 'www-chrishou-se'
  }
  dependsOn: [
    webApp
  ]
}

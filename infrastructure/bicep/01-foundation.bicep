param location string = resourceGroup().location
param subnetConfiguration subnetConfigurationsType
param vnetName string
param workloadName string
param environmentSuffix string
param logAnalyticsRetentionInDays int
param buildId string = substring(newGuid(), 0, 8)

@export()
type subnetConfigurationType = {
  name: string
  addressPrefix: string
  delegation: string
}

@export()
type subnetConfigurationsType = {
  webAppOutboundSubnet: subnetConfigurationType
  webAppInboundSubnet: subnetConfigurationType
  databaseSubnet: subnetConfigurationType
  servicesSubnet: subnetConfigurationType
  appGwSubnet: subnetConfigurationType
}

// Subnets
var webAppOutboundSubnetDeploymentName = '${subnetConfiguration.webAppOutboundSubnet.name}-${buildId}'
var webAppInboundSubnetDeploymentName = '${subnetConfiguration.webAppInboundSubnet.name}-${buildId}'
var databaseSubnetDeploymentName = 'database-subnet-${buildId}'
var servicesSubnetDeploymentName = 'services-subnet-${buildId}'
var appGwSubnetDeploymentName = 'appGw-subnet-${buildId}'

// NSGs
var defaultNsgName = '${workloadName}-${environmentSuffix}-nsg'
var defaultNsgDeploymentName = '${defaultNsgName}-${buildId}'

var appGwNsgName = '${workloadName}-${environmentSuffix}-appGw-nsg'
var appGwNsgDeploymentName = '${appGwNsgName}-${buildId}'

// Log Analytics
var logAnalyticsWorkspaceName = '${workloadName}-${environmentSuffix}-laws'
var logAnalyticsDeploymentName = '${logAnalyticsWorkspaceName}-${buildId}'

// Key Vault
var keyVaultName = '${workloadName}-${environmentSuffix}-kv'
var keyVaultDeploymentName = '${keyVaultName}-${buildId}'


module laws './modules/logAnalytics/logAnalyticsWorkspace.bicep' = {
  name: logAnalyticsDeploymentName
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    location: location
    retentionInDays: logAnalyticsRetentionInDays
  }
}

module nsg './modules/networkSecurityGroup/allowVnetNetworkSecurityGroup.bicep' = {
  name: defaultNsgDeploymentName
  params: {
    nsgName: defaultNsgName
    location: location
    logAnalyticsWorkspaceResourceId: laws.outputs.id
  }
}

module appGwNsg './modules/networkSecurityGroup/applicationGatewayNetworkSecurityGroup.bicep' = {
  name: appGwNsgDeploymentName
  params: {
    location: location
    logAnalyticsWorkspaceResourceId: laws.outputs.id
    networkSecurityGroupName: appGwNsgName
    appGatewaySubnetAddressSpace: subnetConfiguration.appGwSubnet.addressPrefix
  }
}

// Added manual dependencies on each subnet to force serial deployment since it seems like
// deploying these in parallel leads to some kind of race condtion

module webAppOutboundSubnet './modules/virtualNetwork/subnet.bicep' = {
  name: webAppOutboundSubnetDeploymentName
  params: {
    subnetName: subnetConfiguration.webAppOutboundSubnet.name
    addressPrefix: subnetConfiguration.webAppOutboundSubnet.addressPrefix
    delegation: subnetConfiguration.webAppOutboundSubnet.delegation
    vnetName: vnetName
    nsgResourceId: nsg.outputs.id
  }
}

module webAppInboundSubnet './modules/virtualNetwork/subnet.bicep' = {
  name: webAppInboundSubnetDeploymentName
  params: {
    subnetName: subnetConfiguration.webAppInboundSubnet.name
    addressPrefix: subnetConfiguration.webAppInboundSubnet.addressPrefix
    delegation: subnetConfiguration.webAppInboundSubnet.delegation
    vnetName: vnetName
    nsgResourceId: nsg.outputs.id
  }
  dependsOn: [
    webAppOutboundSubnet
  ]
}

module databaseSubnet './modules/virtualNetwork/subnet.bicep' = {
  name: databaseSubnetDeploymentName
  params: {
    subnetName: subnetConfiguration.databaseSubnet.name
    addressPrefix: subnetConfiguration.databaseSubnet.addressPrefix
    delegation: subnetConfiguration.databaseSubnet.delegation
    vnetName: vnetName
    nsgResourceId: nsg.outputs.id
  }
  dependsOn: [
    webAppInboundSubnet
  ]
}

module servicesSubnet './modules/virtualNetwork/subnet.bicep' = {
  name: servicesSubnetDeploymentName
  params: {
    subnetName: subnetConfiguration.servicesSubnet.name
    addressPrefix: subnetConfiguration.servicesSubnet.addressPrefix
    delegation: subnetConfiguration.servicesSubnet.delegation
    vnetName: vnetName
    serviceEndpoints: ['Microsoft.Storage']
    nsgResourceId: nsg.outputs.id
  }
  dependsOn: [
    databaseSubnet
  ]
}

module appGwSubnet './modules/virtualNetwork/subnet.bicep' = {
  name: appGwSubnetDeploymentName
  params: {
    subnetName: subnetConfiguration.appGwSubnet.name
    addressPrefix: subnetConfiguration.appGwSubnet.addressPrefix
    delegation: subnetConfiguration.appGwSubnet.delegation
    vnetName: vnetName
    nsgResourceId: appGwNsg.outputs.id
  }
  dependsOn: [
    servicesSubnet
  ]
}

module kv './modules/keyVault/privateKeyVault.bicep' = {
  name: keyVaultDeploymentName
  params: {
    location: location
    buildId: buildId
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceResourceId: laws.outputs.id 
    vnetName: vnetName
    servicesSubnetResourceId: servicesSubnet.outputs.subnetId
  }
}

output webAppOutboundSubnetId string = webAppOutboundSubnet.outputs.subnetId
output webAppInboundSubnetId string = webAppInboundSubnet.outputs.subnetId
output databaseSubnet string = databaseSubnet.outputs.subnetId
output servicesSubnetId string = servicesSubnet.outputs.subnetId
output appGwSubnetId string = appGwSubnet.outputs.subnetId

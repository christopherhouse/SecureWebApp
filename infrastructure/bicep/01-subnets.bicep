param subnetConfiguration subnetConfigurationsType
param vnetName string

@metadata({
  notes: 'Currently the NSG that is being used for this parameter has the default rulest that are created when a new NSG is created. This meets current requirements, however the NSG will likely need to evolve over time.  As it evolves, it will make sense to build out additional NSGs to accomodate subnet-specific rules.  This template should similarly evolve, to support passing those resource IDs in as parameters'
})
param defaultNsgResourceId string
param buildId string

@export()
type subnetConfigurationType = {
  name: string
  addressPrefix: string
  delegation: string
}

@export()
type subnetConfigurationsType = {
  webAppSubnet: subnetConfigurationType
  databaseSubnet: subnetConfigurationType
  servicesSubnet: subnetConfigurationType
  appGwSubnet: subnetConfigurationType
}

var webAppSubnetDeploymentName = 'webApp-subnet-${buildId}'
var databaseSubnetDeploymentName = 'database-subnet-${buildId}'
var servicesSubnetDeploymentName = 'services-subnet-${buildId}'
var appGwSubnetDeploymentName = 'appGw-subnet-${buildId}'

// Added manual dependencies on each subnet to force serial deployment since it seems like
// deploying these in parallel leads to some kind of race condtion

module webAppSubnet './modules/virtualNetwork/subnet.bicep' = {
  name: webAppSubnetDeploymentName
  params: {
    subnetName: subnetConfiguration.webAppSubnet.name
    addressPrefix: subnetConfiguration.webAppSubnet.addressPrefix
    delegation: subnetConfiguration.webAppSubnet.delegation
    vnetName: vnetName
    nsgResourceId: defaultNsgResourceId
  }
}

module databaseSubnet './modules/virtualNetwork/subnet.bicep' = {
  name: databaseSubnetDeploymentName
  params: {
    subnetName: subnetConfiguration.databaseSubnet.name
    addressPrefix: subnetConfiguration.databaseSubnet.addressPrefix
    delegation: subnetConfiguration.databaseSubnet.delegation
    vnetName: vnetName
    nsgResourceId: defaultNsgResourceId
  }
  dependsOn: [
    webAppSubnet
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
    nsgResourceId: defaultNsgResourceId
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
  }
  dependsOn: [
    servicesSubnet
  ]
}

output webAppSubnetId string = webAppSubnet.outputs.subnetId
output databaseSubnet string = databaseSubnet.outputs.subnetId
output servicesSubnetId string = servicesSubnet.outputs.subnetId
output appGwSubnetId string = appGwSubnet.outputs.subnetId

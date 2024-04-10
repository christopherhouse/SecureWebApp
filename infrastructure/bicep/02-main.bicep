param location string = resourceGroup().location
param workloadName string
param environmentSuffix string
param vnetName string
param webSubnetName string
param servicesSubnetName string
param appGatewaySubnetName string
param buildId string = substring(newGuid(), 0, 9)

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

resource webSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: webSubnetName
  parent: vnet
}

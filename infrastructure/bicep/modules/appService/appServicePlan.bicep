@description('The name of the App Service Plan to create')
param appServicePlanName string

@description('The Azure region where the App Service Plan will be created')
param location string

@description('The SKU name of the App Service Plan')
@allowed(['S1', 'S2', 'S3', 'P1v3', 'P2v3', 'P3v3', 'P1mv3', 'P2mv3', 'P3mv3'])
param skuName string

@description('The number of workers that the App Service Plan should allocate')
param skuCapacity int = 1

@description('Whether the App Service Plan should be zone redundant')
param zoneRedundant bool

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerSizeId: 0
    zoneRedundant: zoneRedundant
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}

output id string = appServicePlan.id

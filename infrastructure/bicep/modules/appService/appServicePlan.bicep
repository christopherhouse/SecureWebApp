param appServicePlanName string
param location string
@allowed(['S1', 'S2', 'S3', 'P1v3', 'P2v3', 'P3v3', 'P1mv3', 'P2mv3', 'P3mv3'])
param skuName string
param skuCapacity int = 1
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

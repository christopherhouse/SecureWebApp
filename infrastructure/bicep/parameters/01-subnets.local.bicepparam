using '../01-subnets.bicep'
param location = 'eastus2'
param vnetName = ''
param workloadName = ''
param environmentSuffix = ''
param subnetConfiguration = {
  appGwSubnet: {
    name: 'app-gw-subnet'
    addressPrefix: ''
    delegation: 'none'
  }
  webAppSubnet: {
    name: 'web-app-subnet'
    addressPrefix: ''
    delegation: 'Microsoft.Web/serverFarms'
  }
  databaseSubnet: {
    name: 'database-subnet'
    addressPrefix: ''
    delegation: 'none'
  }
  servicesSubnet: {
    name: 'services-subnet'
    addressPrefix: ''
    delegation: 'none'
  }
}

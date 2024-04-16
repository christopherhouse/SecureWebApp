using '../01-foundation.bicep'
param location = 'eastus2'
param vnetName = 'bplus-dev-vnet'
param workloadName = 'bplus'
param environmentSuffix = 'dev'
param subnetConfiguration = {
  appGwSubnet: {
    name: 'app-gw-subnet'
    addressPrefix: '10.72.106.224/27'
    delegation: 'none'
  }
  webAppOutboundSubnet: {
    name: 'web-app-outbound-subnet'
    addressPrefix: '10.72.106.128/26'
    delegation: 'Microsoft.Web/serverFarms'
  }
  webAppInboundSubnet: {
    name: 'web-app-inbound-subnet'
    addressPrefix: '10.72.107.192/27'
    delegation: 'none'
  }
  databaseSubnet: {
    name: 'database-subnet'
    addressPrefix: '10.72.106.0/26'
    delegation: 'none'
  }
  servicesSubnet: {
    name: 'services-subnet'
    addressPrefix: '10.72.106.64/26'
    delegation: 'none'
  }
}
param logAnalyticsRetentionInDays = 90

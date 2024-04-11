using '../01-foundation.bicep'
param location = 'eastus2'
param vnetName = 'bplus-loc-vnet'
param workloadName = 'bplus'
param environmentSuffix = 'loc'
param subnetConfiguration = {
  appGwSubnet: {
    name: 'app-gw-subnet'
    addressPrefix: '10.0.1.0/24'
    delegation: 'none'
  }
  webAppOutboundSubnet: {
    name: 'web-app-outbound-subnet'
    addressPrefix: '10.0.2.0/24'
    delegation: 'Microsoft.Web/serverFarms'
  }
  webAppInboundSubnet: {
    name: 'web-app-inbound-subnet'
    addressPrefix: '10.0.3.0/24'
    delegation: 'none'
  }
  databaseSubnet: {
    name: 'database-subnet'
    addressPrefix: '10.0.4.0/24'
    delegation: 'none'
  }
  servicesSubnet: {
    name: 'services-subnet'
    addressPrefix: '10.0.5.0/24'
    delegation: 'none'
  }
}
param logAnalyticsRetentionInDays = 90

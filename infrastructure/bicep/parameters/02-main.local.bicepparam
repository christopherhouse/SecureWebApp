using '../02-main.bicep'
param location = 'eastus2'
param workloadName = 'bicplus'
param environmentSuffix = 'loc'
param vnetName = 'bicplus-loc-vnet'
param webSubnetName = 'web-app-subnet'
param servicesSubnetName = 'services-subnet'
param appGatewaySubnetName = 'app-gw-subnet'
param enableZoneRedundancy = false
@allowed(['S1', 'S2', 'S3', 'P1v3', 'P2v3', 'P3v3', 'P1mv3', 'P2mv3', 'P3mv3'])
param appServicePlanSku = 'S1'

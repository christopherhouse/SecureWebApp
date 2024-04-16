using '../02-main.bicep'
param location = 'eastus2'
param workloadName = 'bplus'
param environmentSuffix = 'dev'
param vnetName = 'bplus-dev-vnet'
param webInboundSubnetName = 'web-app-inbound-subnet'
param webOutboundSubnetName = 'web-app-outbound-subnet'
param servicesSubnetName = 'services-subnet'
param appGatewaySubnetName = 'app-gw-subnet'
param enableZoneRedundancy = false
param appGatewayMinInstances = 1
param appGatewayMaxInstances = 3
param appServicePlanSku = 'S1'
param logAnalyticsWorkspaceName = 'bplus-dev-laws'
param keyVaultName = 'bplus-dev-kv'
param sqlAdminEntraObjectId = 'fa4dfee7-ff0a-4a6c-962c-c9aadb5c5930'
param sqlAdminLoginName = 'BrotherPlus_SQL_Admins_Dev'
param sqlAdminPrincipalType = 'Group'
param databaseSubnetName = 'database-subnet'
param sqlCollation = 'SQL_Latin1_General_CP1_CI_AS'
param sqlDatabaseName = 'BrotherPlusDB'
param sqlvCpuCount = 2
param sqlDatabaseMaxSizeInGb = 32
param sqlBackupStorageRedundancy = 'Local'
param sqlLicenseType = 'LicenseIncluded'
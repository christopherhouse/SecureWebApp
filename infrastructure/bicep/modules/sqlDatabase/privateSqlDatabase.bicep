@description('The name of the Azure SQL Server to create')
param sqlServerName string

@description('The Azure region where resources will be created')
param location string

@description('The object ID of the Azure AD user or group that will be the SQL Server admin')
param sqlAdminEntraObjectId string

@description('The login name of the SQL Server admin')
param sqlAdminLoginName string

@description('The principal type of the SQL Server admin')
@allowed(['User', 'Group', 'Application'])
param sqlAdminPrincipalType string

@description('The resource ID of the virtual network where the SQL Server will be deployed')
param vnetResourceId string

@description('The resource ID of the subnet where the SQL Server will be deployed')
param databaseSubnetResourceId string

@description('The name of the Azure SQL Database to create')
param databaseName string

@description('Indicates whether or not services will be deployed as zone redundant')
param enableZoneRedundancy bool = false

@description('The maximum size of the Azure SQL Database in GB')
param databaseMaxSizeInGb int

@description('The number of vCPUs to allocate to the Azure SQL Database')
param vCpuCount int

@description('The collation of the Azure SQL Database')
param sqlCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('The type of redundancy to use for the backup storage')
@allowed(['Local', 'Geo', 'Zone', 'GeoZone'])
param backupStorageRedundancy string = 'Local'

@description('The type of license to use for the Azure SQL Server, use BasePrice to bring your own license')
@allowed(['LicenseIncluded', 'BasePrice'])
param sqlLicenseType string = 'LicenseIncluded'

@description('The resource ID of the Log Analytics workspace to send diagnostics data to')
param logAnalyticsWorkspaceResourceId string

@description('The build ID, used to create unique deployment names')
param buildId string

var dnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var dnsDeploymentName = '${dnsZoneName}-${buildId}'

var peName = '${sqlServerName}-pe'
var peDeploymentName = '${peName}-${buildId}'

var dbMaxSizeInBytes = databaseMaxSizeInGb * 1024 * 1024 * 1024

resource srv 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      login: sqlAdminLoginName
      sid: sqlAdminEntraObjectId
      principalType: sqlAdminPrincipalType
      azureADOnlyAuthentication: true
      tenantId: subscription().tenantId
    }
    publicNetworkAccess: 'Disabled'
    minimalTlsVersion: '1.2'
  }
}

module dns '../dns/privateDnsZone.bicep' = {
  name: dnsDeploymentName
  params: {
    zoneName: dnsZoneName
    vnetResourceId: vnetResourceId
  }
}

module pe '../privateEndpoint/privateEndpoint.bicep' = {
  name: peDeploymentName
  params: {
    location: location
    dnsZoneId: dns.outputs.id
    groupId: 'sqlServer'
    privateEndpointName: peName
    subnetId: databaseSubnetResourceId
    targetResourceId: srv.id
  }
}

resource db 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: databaseName
  parent: srv
  location: location
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    family:'Gen5'
    capacity: vCpuCount
  }
  properties: {
    collation: sqlCollation
    maxSizeBytes: dbMaxSizeInBytes
    zoneRedundant: enableZoneRedundancy
    licenseType: sqlLicenseType
    requestedBackupStorageRedundancy: backupStorageRedundancy
  }
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: db
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}


output id string = srv.id
output name string = srv.name
output dbName string = db.name
output dbId string = db.id

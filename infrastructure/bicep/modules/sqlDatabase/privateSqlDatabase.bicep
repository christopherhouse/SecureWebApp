param sqlServerName string
param location string
param sqlAdminEntraObjectId string
param sqlAdminLoginName string
@allowed(['User', 'Group', 'Application'])
param sqlAdminPrincipalType string
param vnetResourceId string
param databaseSubnetResourceId string
param databaseName string
param enableZoneRedundancy bool = false
param databaseMaxSizeInGb int
param vCpuCount int
param sqlCollation string = 'SQL_Latin1_General_CP1_CI_AS'
@allowed(['Local', 'Geo', 'Zone', 'GeoZone'])
param backupStorageRedundancy string = 'Local'
@allowed(['LicenseIncluded', 'BasePrice'])
param sqlLicenseType string = 'LicenseIncluded'
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

output id string = srv.id
output name string = srv.name
output dbName string = db.name
output dbId string = db.id

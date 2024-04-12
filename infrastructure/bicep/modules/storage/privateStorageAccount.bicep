param storageAccountName string
param buildId string
param location string
param subnetId string
param keyVaultName string
param storageConnectionStringSecretName string
param zoneRedundant bool
param vnetResourceId string

var blobPrivateEndpointName = '${storageAccountName}-blob-pe'
var filePrivateEndpointName = '${storageAccountName}-file-pe'
var queuePrivateEndpointName = '${storageAccountName}-queue-pe'
var tablePrivateEndpointName = '${storageAccountName}-table-pe'

var blobPrivateEndpointDeploymentName = '${blobPrivateEndpointName}-${buildId}'
var filePrivateEndpointDeploymentName = '${filePrivateEndpointName}-${buildId}'
var queuePrivateEndpointDeploymentName = '${queuePrivateEndpointName}-${buildId}'
var tablePrivateEndpointDeploymentName = '${tablePrivateEndpointName}-${buildId}'

var storageAccountDeploymentName = '${storageAccountName}-mod-${buildId}'

var storageSku = zoneRedundant ? 'Standard_ZRS' : 'Standard_LRS'

var dnsDeploymentName = 'storage-dns-${buildId}'

module dns './storagePrivateDns.bicep' = {
  name: dnsDeploymentName
  params: {
    buildId: buildId
    vnetResourceId: vnetResourceId
  }
}

module storage './storageAccount.bicep' = {
  name: storageAccountDeploymentName
  params: {
    storageAccountName: storageAccountName
    location: location
    buildId: buildId
    keyVaultName: keyVaultName
    storageConnectionStringSecretName: storageConnectionStringSecretName
    storageAccountSku: storageSku
  }
}

module blobPe '../privateEndpoint/privateEndpoint.bicep' = {
  name: blobPrivateEndpointDeploymentName
  params: {
    dnsZoneId: dns.outputs.blobDnsZoneId
    groupId: 'blob'
    location: location
    privateEndpointName: blobPrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.outputs.id
  }
}

module filePe '../privateEndpoint/privateEndpoint.bicep' = {
  name: filePrivateEndpointDeploymentName
  params: {
    dnsZoneId: dns.outputs.fileDnsZoneId
    groupId: 'file'
    location: location
    privateEndpointName: filePrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.outputs.id
  }
}

module queuePe '../privateEndpoint/privateEndpoint.bicep' = {
  name: queuePrivateEndpointDeploymentName
  params: {
    dnsZoneId: dns.outputs.queueDnsZoneId
    groupId: 'queue'
    location: location
    privateEndpointName: queuePrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.outputs.id
  }
}

module tablePe '../privateEndpoint/privateEndpoint.bicep' = {
  name: tablePrivateEndpointDeploymentName
  params: {
    dnsZoneId: dns.outputs.tableDnsZoneId
    groupId: 'table'
    location: location
    privateEndpointName: tablePrivateEndpointName
    subnetId: subnetId
    targetResourceId: storage.outputs.id
  }
}

output id string = storage.outputs.id
output name string = storage.outputs.name
output connectionStringSecretUri string = storage.outputs.connectionStringSecretUri

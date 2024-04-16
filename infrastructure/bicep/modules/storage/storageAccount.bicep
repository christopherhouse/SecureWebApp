@description('The name of the storage account to create')
param storageAccountName string

@description('The Azure region where the storage account should be created')
param location string

@description('The name of the secret in the Key Vault that will store the storage account connection string')
param storageConnectionStringSecretName string

@description('The SKU of the storage account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageAccountSku string

@description('The name of the Key Vault where the storage account connection string will be stored')
param keyVaultName string

@description('The build ID to append to the deployment name')
param buildId string

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountSku
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
  }
}

module blobSecret '../keyVault/keyVaultSecret.bicep' = if (length(storageConnectionStringSecretName) > 0 && length(keyVaultName) > 0) {
  name: '${storageConnectionStringSecretName}-${buildId}'
  params: {
    keyVaultName: keyVaultName
    secretName: storageConnectionStringSecretName
    secretValue: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  }
}

output id string = storage.id
output name string = storage.name
output connectionStringSecretUri string = blobSecret.outputs.secretUri

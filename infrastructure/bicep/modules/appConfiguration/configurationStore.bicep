param appConfigName string
param location string
param logAnalyticsWorkspaceId string
param keyVaultName string
param vnetResourceId string
param servicesSubnetResourceId string
param buildId  string

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

var privateDnsZoneName = 'privatelink.azconfig.io'
var privateDnsZoneDeploymentName = '${privateDnsZoneName}-${buildId}'

var appConfigPeName = '${appConfigName}-pe'
var appConfigPeDeploymentName = '${appConfigPeName}-${buildId}'

var uamiName = '${appConfigName}-uami'

var readonlyKey = filter(appConfig.listKeys().value, k => k.name == 'Primary Read Only')[0]
var readOnlyConnectionString = '${appConfig.properties.endpoint};Id=${readonlyKey.id};Secret=${readonlyKey.value}'
var readOnlyKeySecretDeploymentName = '${appConfigName}-ro-connstr-${buildId}'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

resource appConfigUami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: uamiName
  location: location
}

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: appConfigName
  location: location
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appConfigUami.id}': {}
    }
  }
  properties: {
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
    softDeleteRetentionInDays: 7
  }
}

module dns '../dns/privateDnsZone.bicep' = {
  name: privateDnsZoneDeploymentName
  params: {
    vnetResourceId: vnetResourceId
    zoneName: privateDnsZoneName
  }
}

module pe '../privateEndpoint/privateEndpoint.bicep' = {
  name: appConfigPeDeploymentName
  params: {
    location: location
    dnsZoneId: dns.outputs.id
    groupId: 'configurationStores'
    privateEndpointName: appConfigPeName
    subnetId: servicesSubnetResourceId
    targetResourceId: appConfig.id
  }
}

resource kvSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: keyVaultSecretsUserRoleId
}

resource ra 'Microsoft.Authorization/roleAssignments@2022-04-01'= {
  name: guid(kv.id, uamiName, kvSecretsUserRole.id)
  scope: kv
  properties: {
    principalId: appConfigUami.properties.principalId
    roleDefinitionId: kvSecretsUserRole.id
    principalType: 'ServicePrincipal'
  }
}

module kvSecret '../keyVault/keyVaultSecret.bicep' = {
  name: readOnlyKeySecretDeploymentName
  params: {
    keyVaultName: keyVaultName
    secretName: 'appConfigConnectionString'
    secretValue: readOnlyConnectionString
  }
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: appConfig
  properties: {
    workspaceId: logAnalyticsWorkspaceId
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
  }
}

output id string = appConfig.id
output name string = appConfig.name
output appConfigConnectionStringSecretUri string = kvSecret.outputs.secretUri

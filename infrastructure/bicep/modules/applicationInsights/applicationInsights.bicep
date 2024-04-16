@description('The name of the App Insights resource to create')
param appInsightsName string

@description('The Azure region in which to create the App Insights resource')
param location string

@description('The ID of the Log Analytics workspace to link to the App Insights resource')
param logAnalyticsWorkspaceId string

@description('The name of the Key Vault to store the App Insights connection string and instrumentation key')
param keyVaultName string

@description('The build ID to  append to deployment names')
param buildId string

resource ai 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

module connectionString '../keyVault/keyVaultSecret.bicep' = {
  name: 'app-insights-connection-string-${buildId}'
  params: {
    keyVaultName: keyVaultName
    secretName: 'appInsightsConnectionString'
    secretValue: ai.properties.ConnectionString
  }
}

module iKey '../keyVault/keyVaultSecret.bicep' = {
  name: 'app-insights-instrumentationkey-${buildId}'
  params: {
    keyVaultName: keyVaultName
    secretName: 'appInsightsInstrumentationKey'
    secretValue: ai.properties.InstrumentationKey
  }
}

output id string = ai.id
output name string = ai.name
output instrumentationKeySecretUri string = iKey.outputs.secretUri
output connectionStringSecretUri string = connectionString.outputs.secretUri

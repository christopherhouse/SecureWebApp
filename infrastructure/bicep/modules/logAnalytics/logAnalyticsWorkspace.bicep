@description('The name of the Log Analytics workspace to create')
param logAnalyticsWorkspaceName string

@description('The Azure region where the Log Analytics workspace will be created')
param location string

@description('The number of days to retain data in the Log Analytics workspace')
param retentionInDays int

resource laws 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: 'PerGB2018'
    }
  }
}

output id string = laws.id
output name string = laws.name

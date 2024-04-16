@description('The name of the web app to create')
param webAppName string

@description('The Azure region where the web app should be created')
param location string

@description('The ID of the app service plan to use for the web app')
param appServicePlanId string

@description('The ID of the subnet to integrate the web app with for outbound vnet traffic')
param vnetIntegrationSubnetId string

@description('The ID of the Log Analytics workspace to send diagnostic logs to')
param logAnalyticsWorkspaceId string

@description('The ID of the user-assigned managed identity to assign to the web app')
param userAssignedManagedIdentityResourceId string

@description('The URI of the secret in Key Vault containing the Application Insights connection string')
param appInsightsConnectionStringSecretUri string

@description('The URI of the secret in Key Vault containing the App Configuration connection string')
param appConfigurationConnectionStringSecretUri string

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentityResourceId}': {}
    }
  }
  properties: {
    siteConfig: {
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      alwaysOn: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=${appInsightsConnectionStringSecretUri})'
        }
        {
          name: 'APP_CONFIGURATION_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=${appConfigurationConnectionStringSecretUri})'
        }
      ]
    }
    keyVaultReferenceIdentity: userAssignedManagedIdentityResourceId
    serverFarmId: appServicePlanId
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
    virtualNetworkSubnetId: vnetIntegrationSubnetId
  }
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuthenticationLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }      
    ]
  }
}

output id string = webApp.id
output name string = webApp.name
output defaultHostName string = webApp.properties.defaultHostName


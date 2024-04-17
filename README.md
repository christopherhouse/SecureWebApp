# Azure Secure Web App

# 📚 Repository Description and Overview

This repository contains the infrastructure as code (IaC) for a secure web application using Azure App Service. The code is written in Bicep, a declarative language for describing and deploying Azure resources.

# 🏗️ Repository Structure
```
📁infrastructure/
    📁bicep/
        💪01-foundation.bicep
        💪02-main.bicep
        📁modules/
            📁appConfiguration/
            📁applicationGateway/
            📁applicationInsights/
            📁appService/
            📁dns/
            📁keyVault/
            📁logAnalytics/
            📁managedIdentity/
            📁networkSecurityGroup/
            📁privateEndpoint/
            📁sqlDatabase/
            📁storage/
            📁virtualNetwork/
        📁parameters/
    📁scripts/
        📜Deploy-Foundation.ps1
        📜Deploy-Main.ps1
📁README.md
```

# 🚀 Resources

The following Azure resources are deployed by this repository:

- App Service Plan
- Web App
- Application Insights
- App Configuration
- Storage Account
- Application Gateway
- Virtual Network and Subnets
- Log Analytics Workspace

# 🚀 Deployment

## 01-Foundation.bicep Parameters

| Parameter Name | Description | Type | Default Value |
| -------------- | ----------- | ---- | ------------- |
| ...            | ...         | ...  | ...           |

## 02-main.bicep Parameters

| Parameter Name | Description | Type | Default Value |
| -------------- | ----------- | ---- | ------------- |
| `location` | The Azure region where resources will be deployed | string | N/A |
| `appServicePlanName` | The name of the App Service Plan | string | N/A |
| `appServicePlanSku` | The SKU of the App Service Plan | string | N/A |
| `webAppName` | The name of the Web App | string | N/A |
| `vnetResourceId` | The resource ID of the Virtual Network | string | N/A |
| `webAppPrivateLinkSubnetId` | The subnet ID for the Web App's private link | string | N/A |
| `webAppVnetIntegrationSubnetId` | The subnet ID for the Web App's VNet integration | string | N/A |
| `enableZoneRedundancy` | Whether to enable zone redundancy | bool | `false` |
| `logAnalyticsWorkspaceId` | The ID of the Log Analytics Workspace | string | N/A |
| `keyVaultName` | The name of the Key Vault | string | N/A |
| `appInsightsConnectionStringSecretUri` | The secret URI for the App Insights connection string | string | N/A |
| `appConfigurationConnectionStringSecretUri` | The secret URI for the App Configuration connection string | string | N/A |
| ... | ... | ... | ... |

Please replace `...` with the actual parameters and their descriptions, types, and default values.
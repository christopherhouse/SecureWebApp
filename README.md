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

## Overview
This repo contains two top level Bicep templates, 01-foundation.bicep and 02-main.bicep. The 01-foundation.bicep template deploys the foundational resources for the web application, subnets, and Log Analytics workspace. Note 01-foundation.bicep does not create a virtual network, it expects an existing virtual network and will create subnets inside that address space.  The 02-main.bicep template deploys the main resources for the web application, such as the App Service Plan, Web App, Application Insights, and Application Gateway.

## Deployment Steps
1. Deploy the foundational resources using the 01-foundation.bicep template.
2. Add a TLS certificate for your web app to the Key Vault deployed by 01-foundation.bicep.
3. Deploy the main resources using the 02-main.bicep template.

### 01-foundation.bicep Parameters

| Parameter Name | Description | Type | Default Value |
| -------------- | ----------- | ---- | ------------- |
| `location` | The Azure region where resources will be created | string | `resourceGroup().location` |
| `subnetConfiguration` | The subnet configuration for the virtual network, this parameter is a UDT | `subnetConfigurationsType` | N/A |
| `vnetName` | The name of the virtual network where subnets and private endpoints will be created | string | N/A |
| `workloadName` | The name of the workload, used to generate resource names, in the form of [workloadName]-[environmentSuffix]-[resourceTypeAbbreviation] | string | N/A |
| `environmentSuffix` | The environment suffix, representing the environment where resources will be deployed.  Used to generate resource names, in the form of [workloadName]-[environmentSuffix]-[resourceTypeAbbreviation] | string | N/A |
| `logAnalyticsRetentionInDays` | The number of days to retain log data in the Log Analytics workspace | int | N/A |
| `buildId` | The build ID, used to generate unique resource deployment names | string | `substring(newGuid(), 0, 8)` |


## 02-main.bicep Parameters

| Parameter Name | Description | Type | Allowed Values | Default Value |
| -------------- | ----------- | ---- | -------------- | ------------- |
| `location` | The Azure region where resources will be created | string | N/A | `resourceGroup().location` |
| `workloadName` | The name of the workload | string | N/A | N/A |
| `environmentSuffix` | The environment suffix, representing the environment where resources will be deployed | string | N/A | N/A |
| `logAnalyticsWorkspaceName` | The name of the Log Analytics workspace | string | N/A | N/A |
| `keyVaultName` | The name of the Key Vault | string | N/A | N/A |
| `vnetName` | The name of the virtual network | string | N/A | N/A |
| `webInboundSubnetName` | The name of the inbound web subnet | string | N/A | N/A |
| `webOutboundSubnetName` | The name of the outbound web subnet | string | N/A | N/A |
| `databaseSubnetName` | The name of the database subnet | string | N/A | N/A |
| `servicesSubnetName` | The name of the services subnet | string | N/A | N/A |
| `appGatewaySubnetName` | The name of the Application Gateway subnet | string | N/A | N/A |
| `enableZoneRedundancy` | Whether to enable zone redundancy | bool | N/A | `false` |
| `appGatewayMinInstances` | The minimum number of instances for the Application Gateway | int | N/A | `0` |
| `appGatewayMaxInstances` | The maximum number of instances for the Application Gateway | int | N/A | N/A |
| `appServicePlanSku` | The SKU for the App Service Plan | string | 'S1', 'S2', 'S3', 'P1v3', 'P2v3', 'P3v3', 'P1mv3', 'P2mv3', 'P3mv3' | N/A |
| `sqlAdminEntraObjectId` | The object ID for the SQL admin | string | N/A | N/A |
| `sqlAdminLoginName` | The login name for the SQL admin | string | N/A | N/A |
| `sqlAdminPrincipalType` | The principal type for the SQL admin | string | 'User', 'Group', 'Application' | N/A |
| `sqlCollation` | The collation for the SQL database | string | N/A | 'SQL_Latin1_General_CP1_CI_AS' |
| `sqlDatabaseName` | The name of the SQL database | string | N/A | N/A |
| `sqlDatabaseMaxSizeInGb` | The maximum size of the SQL database in GB | int | N/A | N/A |
| `sqlvCpuCount` | The number of vCPUs for the SQL server | int | N/A | N/A |
| `sqlBackupStorageRedundancy` | The backup storage redundancy for the SQL server | string | 'Local', 'Zone', 'Geo', 'GeoZone' | 'Local' |
| `sqlLicenseType` | The license type for the SQL server | string | 'LicenseIncluded', 'BasePrice' | 'LicenseIncluded' |
| `buildId` | The build ID, used to generate unique resource deployment names | string | N/A | `substring(newGuid(), 0, 8)` |

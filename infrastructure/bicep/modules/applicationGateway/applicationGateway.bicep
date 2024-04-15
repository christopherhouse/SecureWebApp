param appGatewayName string
param location string
param subnetResourceId string
param logAnalyticsWorkspaceResourceId string
param keyVaultName string
param webAppFrontEndHostName string
param webAppBackendHostName string
param frontEndCertificateKeyVaultSecretName string
@allowed(['WAV_v2', 'Standard_v2'])
param appGatewaySku string
param appGatewaySkuCapacity int
param zoneRedundant bool = false

var internalGatewayHttpsListener = 'internalGatewayHttpsListener'
var webAppFrontEndPort = 'https_443'
var appGatewayFrontendIp = 'appGatewayFrontendIp'
var webAppSslCert = 'webAppSslCert'
var publicFrontEndIpConfiguration = 'appGatewayPublicFrontendIp'
//var internalGatewayProbeName = 'internalGatewayProbe'
//var internalGatewayBackendSettingsName = 'internalGatewayBackendSettings'
//var internalGatewayBackendAddressPoolName = 'internalGatewayBackendAddressPool'
var webAppProbeName = 'webAppProbe'
var webAppBackendSettingsName = 'webAppBackendSettings'
var webAppGatewayBackendAddressPoolName = 'webAppBackendAddressPool'
var webAppHttpsListener = 'webAppHttpsListener'

var keyVaultSecretId = 'https://${keyVaultName}.${environment().suffixes.keyvaultDns}/secrets/${frontEndCertificateKeyVaultSecretName}'


var zones = zoneRedundant ? ['1', '2', '3'] : []

var publicFrontEndIpConfigurations =  [
  {
    name: publicFrontEndIpConfiguration
    properties: {
      publicIPAddress: {
        id: pip.id
      }
    }
  }
]

// var privateFrontEndIpConfiguration = length(internalGatewayHostName) > 0 ? [{
//   name: 'appGatewayFrontendIp'
//   properties: {
//     privateIPAddress: internalGatewayHostPrivateIp
//     privateIPAllocationMethod: 'Static'
//     subnet: {
//       id: subnetResourceId
//     }
//   }
// }] : []

//var frontEndIpConfigurations = concat(publicFrontEndIpConfigurations, privateFrontEndIpConfiguration)

var webAppBackendAddressPool = {
  name: webAppGatewayBackendAddressPoolName
  properties: {
    backendAddresses: [
      {
        fqdn: webAppBackendHostName
      }
    ]
  }
}

var webAppBackendSettings = {
  name: webAppBackendSettingsName
  properties: {
    port: 443
    protocol: 'Https'
    cookieBasedAffinity: 'Disabled'
    pickHostNameFromBackendAddress: false
    hostName: webAppBackendHostName
    requestTimeout: 30
    probe: {
      id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, webAppProbeName)
    }
  }
}

var webAppRoutingRule = {
  name: 'webAppHttpsRule'
  properties: {
    priority: 4
    ruleType: 'Basic'
    httpListener: {
      id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, webAppHttpsListener)
    }
    backendAddressPool: {
      id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, webAppGatewayBackendAddressPoolName)
    }
    backendHttpSettings: {
      id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, webAppBackendSettingsName)
    }
  }
}

var webAppHttpListener = {
    name: internalGatewayHttpsListener
    properties: {
      hostName: webAppFrontEndHostName
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, appGatewayFrontendIp)
      }
      frontendPort: {
        id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, webAppFrontEndPort)
      }
      protocol: 'Https'
      sslCertificate: {
        id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, webAppSslCert)
      
    }
  }
}

var webAppCert = {
  name: webAppSslCert
  properties: {
    keyVaultSecretId: keyVaultSecretId
  }
}

var gatewayFEPort = [{
  name: webAppFrontEndPort
  properties: {
    port: 443
  }
}]

var webAppGatewayProbe = {
  name: webAppProbeName
  properties: {
    protocol: 'Https'
    host: webAppBackendHostName
    path: '/'
    interval: 30
    timeout: 120
    unhealthyThreshold: 3
  }
}

var pipName = '${appGatewayName}-pip'
var uamiName = '${appGatewayName}-uami'
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource kvSecretUser 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: keyVaultSecretsUserRoleId
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: uamiName
  location: location
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uami.id, kv.id, kvSecretUser.id)
  scope: kv
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: kvSecretUser.id
    principalType: 'ServicePrincipal'
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: pipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: pipName
    }
  }
  zones: zoneRedundant ? ['1', '2', '3'] : []
}

resource appGw 'Microsoft.Network/applicationGateways@2023-04-01' = {
  name: appGatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    sku: {
      name: appGatewaySku
      tier: appGatewaySku
      capacity: appGatewaySkuCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
    frontendIPConfigurations: publicFrontEndIpConfigurations
    frontendPorts: gatewayFEPort
    backendAddressPools: [webAppBackendAddressPool]
    backendHttpSettingsCollection: [webAppBackendSettings]
    httpListeners: [webAppHttpListener]
    requestRoutingRules: [webAppRoutingRule]
    probes: [webAppGatewayProbe]
    sslCertificates: [webAppCert]
    sslPolicy: {
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20220101S'
    }
    webApplicationFirewallConfiguration: appGatewaySku == 'WAF_v2' ? {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      exclusions: []
    } : null
  }
  zones: zones
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: appGw
  properties: {
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

output id string = appGw.id
output name string = appGw.name

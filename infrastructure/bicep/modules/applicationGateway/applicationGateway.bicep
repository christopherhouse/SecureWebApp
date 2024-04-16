//param applicationGateways_cmh_bplus_loc_appgw_name string = 'cmh-bplus-loc-appgw'
param appGatewayName string
param location string
//param publicIPAddresses_cmh_bplus_loc_appgw_pip_externalid string = '/subscriptions/e1f57a36-4892-4716-9a3f-661432b39dbe/resourceGroups/BICPLUS/providers/Microsoft.Network/publicIPAddresses/cmh-bplus-loc-appgw-pip'
@allowed(['Standard_v2', 'WAF_v2'])
param skuName string
param minInstances int = 0
param maxInstances int
param keyVaultName string
param webAppBackendHostName string
param webAppSslCertKeyVaultSecretName string
param vnetName string
param appGatewaySubnetName string
param enableZoneRedundancy bool = false

var zones = enableZoneRedundancy ? ['1', '2', '3'] : []

var keyVaultSecretId = 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/${webAppSslCertKeyVaultSecretName}'
var publicIpName = '${appGatewayName}-pip'

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

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

resource appGwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: appGatewaySubnetName
  parent: vnet
}

resource appGwPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name:publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: publicIpName
    }
  }
  zones: zones
}

var appGatewayIpConfigName = 'appGatewayIpConfig'
var sslCertNmae = 'www'

resource applicationGateways_cmh_bplus_loc_appgw_name_resource 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: appGatewayName
  location: location
  zones: zones
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    sku: {
      name: skuName
      tier: skuName
    }
    gatewayIPConfigurations: [
      {
        name: appGatewayIpConfigName
        id: resourceId('Microsoft.Network/applicationGateways/gatewayIPConfigurations', appGatewayName, appGatewayIpConfigName)
        properties: {
          subnet: {
            id: appGwSubnet.id
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: sslCertNmae
        id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, sslCertNmae)
        properties: {
          keyVaultSecretId: keyVaultSecretId
        }
      }
    ]
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIpIPv4'
        //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/frontendIPConfigurations/appGwPublicFrontendIpIPv4'
        id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwPublicFrontendIpIPv4')
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGwPip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/frontendPorts/port_443'
        id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_443')
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'webAppBackendPool'
        //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/backendAddressPools/webAppBackendPool'
        id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'webAppBackendPool')
        properties: {
          backendAddresses: [
            {
              fqdn: 'bplus-loc-appsvc.azurewebsites.net'
            }
          ]
        }
      }
    ]
    loadDistributionPolicies: []
    backendHttpSettingsCollection: [
      {
        name: 'backendHttpsSettings'
        //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/backendHttpSettingsCollection/backendHttpsSettings'
        id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'backendHttpsSettings')
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          hostName: webAppBackendHostName
          requestTimeout: 20
          probe: {
            //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/probes/backendHttpsSettings22ef1a7b-18f6-4680-8469-dc2c9e0a009_'
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'backendHttpsSettings22ef1a7b-18f6-4680-8469-dc2c9e0a009_')
          }
        }
      }
    ]
    backendSettingsCollection: []
    httpListeners: [
      {
        name: 'publicHttps'
        //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/httpListeners/publicHttps'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'publicHttps')
        properties: {
          frontendIPConfiguration: {
            //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/frontendIPConfigurations/appGwPublicFrontendIpIPv4'
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwPublicFrontendIpIPv4')
          }
          frontendPort: {
            //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/frontendPorts/port_443'
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, sslCertNmae)
          }
          hostNames: []
          requireServerNameIndication: false
          customErrorConfigurations: []
        }
      }
    ]
    listeners: []
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'webAppRule'
        //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/requestRoutingRules/webAppRule'
        id: resourceId('Microsoft.Network/applicationGateways/requestRoutingRules', appGatewayName, 'webAppRule')
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/httpListeners/publicHttps'
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'publicHttps')
          }
          backendAddressPool: {
            //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/backendAddressPools/webAppBackendPool'
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'webAppBackendPool')
          }
          backendHttpSettings: {
            //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/backendHttpSettingsCollection/backendHttpsSettings'
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'backendHttpsSettings')
          }
        }
      }
    ]
    routingRules: []
    probes: [
      {
        name: 'backendHttpsSettings22ef1a7b-18f6-4680-8469-dc2c9e0a009_'
        //id: '${applicationGateways_cmh_bplus_loc_appgw_name_resource.id}/probes/backendHttpsSettings22ef1a7b-18f6-4680-8469-dc2c9e0a009_'
        id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'backendHttpsSettings22ef1a7b-18f6-4680-8469-dc2c9e0a009_')
        properties: {
          protocol: 'Https'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {}
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: minInstances
      maxCapacity: maxInstances
    }
  }
}

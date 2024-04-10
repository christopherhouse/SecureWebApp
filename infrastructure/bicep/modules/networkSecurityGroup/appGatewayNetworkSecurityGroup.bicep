@description('The name of the NSG to create')
param nsgName string

@description('The region where the NSG will be created')
param location string

@description('The resource ID of the Log Analytics workspace where logs will be sent')
param logAnalyticsWorkspaceResourceId string

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [{
      name: 'Allow_Gateway_Manager_To_Any'
      properties: {
        protocol: 'TCP'
        sourcePortRange: '*'
        sourceAddressPrefix: 'GatewayManager'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 1024
        direction: 'Inbound'
        sourcePortRanges: []
        destinationPortRanges: [
          '65200-65535'
        ]
        sourceAddressPrefixes: []
        destinationAddressPrefixes: []
      }
    }]
  }
}

resource laws 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: nsg
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

output id string = nsg.id
output name string = nsg.name

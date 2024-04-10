param subnetName string
param vnetName string
param addressPrefix string
param delegation string = 'none'
param nsgResourceId string = ''
param serviceEndpoints array = []

var serviceEndpointsConfig = [for endpoint in serviceEndpoints: {
  service: endpoint
}]

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: nsgResourceId == '' ? null :{
      id: nsgResourceId
    }
    delegations: delegation == 'none' ? [] : [
      {
        name: delegation
        properties: {
          serviceName: delegation
        }
      }
    ]
    serviceEndpoints: serviceEndpointsConfig
  }
}

output subnetId string = subnet.id

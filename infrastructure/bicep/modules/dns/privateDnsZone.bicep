@description('The name of the private DNS zone to create.')
param zoneName string

@description('The resource ID of the virtual network to link to the private DNS zone.')
param vnetResourceId string

resource zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
  properties: {}
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: zone
  name: uniqueString(zone.id)
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetResourceId
    }
  }
}

output id string = zone.id
output zoneName string = zone.name

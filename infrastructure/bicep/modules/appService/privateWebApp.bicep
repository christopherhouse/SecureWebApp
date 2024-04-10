param appServicePlanName string
param webAppName string
param location string
@allowed(['S1', 'S2', 'S3', 'P1v3', 'P2v3', 'P3v3', 'P1mv3', 'P2mv3', 'P3mv3'])
param appServicePlanSku string
param enableZoneRedundancy bool = false
param vnetResourceId string
param webAppPrivateLinkSubnetId string
param webAppVnetIntegrationSubnetId string
param buildId string

var appServicePlanDeploymentName = '${appServicePlanName}-${buildId}'
var webAppDeploymentName = '${webAppName}-${buildId}'

var dnsZoneName = 'privatelink.azurewebsites.net'
var dnsZoneDeploymentName = '${dnsZoneName}-${buildId}'

var peName = '${webAppName}-pe'
var peDeploymentName = '${peName}-${buildId}'

module asp './appServicePlan.bicep' = {
  name: appServicePlanDeploymentName
  params: {
    location: location
    appServicePlanName: appServicePlanName
    skuName: appServicePlanSku
    zoneRedundant: enableZoneRedundancy
  }
}

module webApp './webApp.bicep' = {
  name: webAppDeploymentName
  params: {
    appServicePlanId: asp.outputs.id
    location: location
    webAppName: webAppName
    vnetIntegrationSubnetId: webAppVnetIntegrationSubnetId
  }
}

module webAppDns '../dns/privateDnsZone.bicep' = {
  name: dnsZoneDeploymentName
  params: {
    vnetResourceId: vnetResourceId
    zoneName: dnsZoneName
  }
}

module webAppPe '../privateEndpoint/privateEndpoint.bicep' = {
  name: peDeploymentName
  params: {
    location: location
    dnsZoneId: webAppDns.outputs.id
    groupId: 'sites'
    privateEndpointName: peName
    subnetId: webAppPrivateLinkSubnetId
    targetResourceId: webApp.outputs.id
  }
}

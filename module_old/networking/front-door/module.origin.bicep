////////////////////////////////////////////////
//// Location and Tags

// param subDeploymentName string = deployment().name
param location string = 'global'
// param tags {
//   *: string
// } = {}

////////////////////////////////////////////////
//// Naming Module

import { name, typeNaming } from '../../governance/naming/module.bicep'

@description('Provide a custom naming schema for the resource. Default is used if not provided.')
param schema object
@description('Define any parameters used for name generation here.')
param naming typeNaming
var varNaming = union(naming, {
  location: location
})

////////////////////////////////////////////////
//// Module Parameter

@description('The name of the cdn profile.')
param profileName string
@description('The identifier key for cross-referencing the resource.')
param identifierKey string

import { originGroup } from './module.types.bicep'
param config originGroup

////////////////////////////////////////////////
//// Default Settings

var varDefaultSettings = {
  sku: 'Standard_AzureFrontDoor'

  identity: {
    type: ''
    userAssignedIdentities: []
  }

  originGroup: {
    healthProbe: {
      enabled: true
      intervalInSeconds: 30
      path: '/'
      protocol: 'Https'
      method: 'GET'
    }
    loadBalancing: {
      additionalLatencyInMilliseconds: 0
      sampleSize: 4
      successfulSamplesRequired: 2
    }
    sessionAffinity: false
    trafficRestorationTimeToHealedOrNewEndpointsInMinutes: 5
    origin: {
      hostName: null
      hostHeader: null
      httpPort: 80
      httpsPort: 443
      priority: 1
      weight: 1
    }
  }
}

////////////////////////////////////////////////

/*

  CDN Profile

*/

resource resCDNProfile 'Microsoft.Cdn/profiles@2023-07-01-preview' existing = {
  name: profileName
}

/*

  CDN origins e.g. the backend where frontdoor directs traffic to.

*/

resource resOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-07-01-preview' = {
  parent: resCDNProfile
  name: name('Microsoft.Cdn/profiles/originGroups', schema, varNaming)
  properties: {
    healthProbeSettings: !(config.?healthProbe.?enabled ?? varDefaultSettings.originGroup.healthProbe.enabled)
      ? null
      : {
          probeIntervalInSeconds: config.?healthProbe.?intervalInSeconds ?? varDefaultSettings.originGroup.healthProbe.intervalInSeconds
          probePath: config.?healthProbe.?path ?? varDefaultSettings.originGroup.healthProbe.path
          probeProtocol: config.?healthProbe.?protocol ?? varDefaultSettings.originGroup.healthProbe.protocol
          probeRequestType: config.?healthProbe.?method ?? varDefaultSettings.originGroup.healthProbe.method
        }
    loadBalancingSettings: {
      additionalLatencyInMilliseconds: config.?loadBalancing.?additionalLatencyInMilliseconds ?? varDefaultSettings.originGroup.loadBalancing.additionalLatencyInMilliseconds
      successfulSamplesRequired: config.?loadBalancing.?successfulSamplesRequired ?? varDefaultSettings.originGroup.loadBalancing.successfulSamplesRequired
      sampleSize: config.?loadBalancing.?sampleSize ?? varDefaultSettings.originGroup.loadBalancing.sampleSize
    }
    sessionAffinityState: (config.?sessionAffinity ?? varDefaultSettings.originGroup.sessionAffinity)
      ? 'Enabled'
      : 'Disabled'
    trafficRestorationTimeToHealedOrNewEndpointsInMinutes: config.?trafficRestorationTimeToHealedOrNewEndpointsInMinutes ?? varDefaultSettings.originGroup.trafficRestorationTimeToHealedOrNewEndpointsInMinutes
  }
}

resource resOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-07-01-preview' = [
  for (origin, index) in items(config.origins): {
    name: name(
      'Microsoft.Cdn/profiles/originGroups/origins',
      schema,
      union(
        {
          index: index + 1
          key: origin.key
          location: location
        },
        varNaming
      )
    )
    parent: resOriginGroup
    properties: {
      // azureOrigin: {
      //   id: 'string'
      // }

      hostName: origin.value.?hostName
      httpPort: origin.value.?httpPort ?? varDefaultSettings.originGroup.origin.httpPort
      httpsPort: origin.value.?httpsPort ?? varDefaultSettings.originGroup.origin.httpsPort
      originHostHeader: origin.value.?hostHeader ?? varDefaultSettings.originGroup.origin.hostHeader
      priority: origin.value.?priority ?? varDefaultSettings.originGroup.origin.priority
      weight: origin.value.?weight ?? varDefaultSettings.originGroup.origin.weight

      //enabledState: 'string'
      //enforceCertificateNameCheck: bool

      //sharedPrivateLinkResource: {
      //  groupId: 'string'
      //  privateLink: {
      //    id: 'string'
      //  }
      //  privateLinkLocation: 'string'
      //  requestMessage: 'string'
      //  status: 'string'
      //}
    }
  }
]

output apiVersion string = resOriginGroup.apiVersion
output key string = identifierKey
output id string = resOriginGroup.id
output name string = resOriginGroup.name

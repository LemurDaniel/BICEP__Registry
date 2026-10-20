////////////////////////////////////////////////
//// Location and Tags

param subDeploymentName string = deployment().name
// param location string = resourceGroup().location
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
var varNaming = naming

////////////////////////////////////////////////
//// Module Parameter

type typePeeringConfig = {
  id: string

  naming: typeNaming?

  allowForwardedTraffic: bool
  allowGatewayTransit: bool
  allowVirtualNetworkAccess: bool
  useRemoteGateways: bool
}
param sourceVnet typePeeringConfig
param remoteVnet typePeeringConfig

/*

*/

var varSourceVnet = {
  id: sourceVnet.id
  name: split(sourceVnet.id, '/')[?8]
  resourceGroup: split(sourceVnet.id, '/')[?4]
  subscriptionId: split(sourceVnet.id, '/')[?2]
}

module peerSourceToRemote './peering.dual.resource.bicep' = {
  name: format('{0}-sourcepeer', subDeploymentName)
  scope: resourceGroup(varSourceVnet.subscriptionId, varSourceVnet.resourceGroup)
  params: {
    config: {
      sourceVnetName: varSourceVnet.name
      remoteVnetId: varRemoteVnet.id

      // 1. Use the general naming parameters.
      // 2. SourceVnetName and remoteVnetName.
      // 3. Use the endpoint specific naming parameters.
      // 4. Use the name property if provided.
      name: name(
        'Microsoft.Network/virtualNetworks/virtualNetworkPeerings',
        schema,
        union(
          varNaming,
          {
            remoteVnetName: varRemoteVnet.name
            sourceVnetName: varSourceVnet.name
          },
          sourceVnet.?naming ?? {}
        )
      )

      allowForwardedTraffic: sourceVnet.allowForwardedTraffic
      allowGatewayTransit: sourceVnet.allowGatewayTransit
      allowVirtualNetworkAccess: sourceVnet.allowVirtualNetworkAccess
      useRemoteGateways: sourceVnet.useRemoteGateways
    }
  }
}

var varRemoteVnet = {
  id: remoteVnet.id
  name: split(remoteVnet.id, '/')[?8]
  resourceGroup: split(remoteVnet.id, '/')[?4]
  subscriptionId: split(remoteVnet.id, '/')[?2]
}

module peerRemoteToSource './peering.dual.resource.bicep' = {
  name: format('{0}-remotepeer', subDeploymentName)
  scope: resourceGroup(varRemoteVnet.subscriptionId, varRemoteVnet.resourceGroup)
  params: {
    config: {
      sourceVnetName: varRemoteVnet.name
      remoteVnetId: varSourceVnet.id

      // 1. Use the general naming parameters.
      // 2. SourceVnetName and remoteVnetName.
      // 3. Use the endpoint specific naming parameters.
      // 4. Use the name property if provided.
      name: name(
        'Microsoft.Network/virtualNetworks/virtualNetworkPeerings',
        schema,
        union(
          varNaming,
          {
            remoteVnetName: varSourceVnet.name
            sourceVnetName: varRemoteVnet.name
          },
          sourceVnet.?naming ?? {}
        )
      )

      allowForwardedTraffic: remoteVnet.allowForwardedTraffic
      allowGatewayTransit: remoteVnet.allowGatewayTransit
      allowVirtualNetworkAccess: remoteVnet.allowVirtualNetworkAccess
      useRemoteGateways: remoteVnet.useRemoteGateways
    }
  }
}

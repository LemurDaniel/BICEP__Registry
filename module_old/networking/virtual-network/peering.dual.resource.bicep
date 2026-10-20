/*

  This is a helper module for the primary peerVnet module.

  Vnets are often in different resource groups.

  This module can be used by the peerVnet-module, to deploy peerings in different resource groups.
*/

param config {
  name: string

  sourceVnetName: string
  remoteVnetId: string

  allowVirtualNetworkAccess: bool
  allowForwardedTraffic: bool
  allowGatewayTransit: bool
  useRemoteGateways: bool
}

resource resSourceVnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: config.sourceVnetName
}

resource resPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: format('peer-{0}', config.name)
  parent: resSourceVnet
  properties: {
    remoteVirtualNetwork: {
      id: config.remoteVnetId
    }

    allowVirtualNetworkAccess: config.allowVirtualNetworkAccess
    allowForwardedTraffic: config.allowForwardedTraffic
    allowGatewayTransit: config.allowGatewayTransit
    useRemoteGateways: config.useRemoteGateways
  }
}

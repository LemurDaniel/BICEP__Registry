import { typeNaming } from '../../governance/naming/module.bicep'

@export()
type virtualNetworkConfig = {
  addressSpace: string?
  addressSpaces: string[]?
  subnet: {
    *: typeSubnet
  }

  nsg: {
    *: {
      naming: typeNaming?

      inbound: {
        *: typeNsgRule?
      }?
      outbound: {
        *: typeNsgRule?
      }?
    }
  }?

  @description('Configures only peering on the source network. The peering on the remote network must be configured separately.')
  singlePeerings: typeSinglePeerings[]?

  @description('Configures both peerings at once.')
  dualPeerings: typeDualPeerings[]?
}

@export()
type typeSubnet = {
  naming: typeNaming?

  @description('Create a subnet based on a CIDR-Range and the ith-subnet in that range.')
  cidr: {
    mask: 30 | 29 | 28 | 27 | 26 | 25 | 24 | 23 | 22 | 21 | 20 | 19 | 18 | 17 | 16?
    index: int?
  }?
  addressPrefix: string?
  addressPrefixIpv6: string?

  serviceEndpoints: string[]?
  delegations: string[]?
  routeTable: string?
  securityGroup: string?
}

@export()
type typeNsgRule = {
  access: string
  priority: int
  protocol: 'Icmp' | 'Tcp' | 'Udp' | 'Esp' | 'Ah' | 'Icmpv6' | '*'?
  sourcePort: string?
  sourcePorts: string[]?
  destinationPort: string?
  destinationPorts: string[]?
  sourceAddress: string?
  sourceAddresses: string[]?
  destinationAddress: string?
  destinationAddresses: string[]?
}

@export()
type typeSinglePeerings = {
  remoteVnetId: string

  source: {
    naming: typeNaming?

    allowForwardedTraffic: bool?
    allowGatewayTransit: bool?
    allowVirtualNetworkAccess: bool?
    useRemoteGateways: bool?
  }?
}

@export()
type typeDualPeerings = {
  remoteVnetId: string

  source: {
    naming: typeNaming?

    allowForwardedTraffic: bool?
    allowGatewayTransit: bool?
    allowVirtualNetworkAccess: bool?
    useRemoteGateways: bool?
  }?

  remote: {
    naming: typeNaming?

    allowForwardedTraffic: bool?
    allowGatewayTransit: bool?
    allowVirtualNetworkAccess: bool?
    useRemoteGateways: bool?
  }?
}

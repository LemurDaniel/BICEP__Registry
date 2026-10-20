import { GetSegmentFromId } from '../../governance/custom-function/module.bicep'

////////////////////////////////////////////////
//// Location and Tags

param subDeploymentName string = deployment().name
param location string = resourceGroup().location
param tags {
  *: string
} = {}

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

import { virtualNetworkConfig } from 'module.type.bicep'
param config virtualNetworkConfig

/*

  ###############################################################
  ## Network Security Group Resource
  ###############################################################
  
*/

var varDefaultSettings = {
  network: {
    addressSpace: '10.0.0.0/16'
    subnet: {
      cidr: 28
    }
  }
  peering: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  networkSecurityRule: {
    inbound: {
      direction: 'Inbound'
      protocol: 'Tcp'
      sourcePort: '*'
      destinationPort: '*'
      sourceAddress: '*'
      destinationAddress: '*'
    }
    outbound: {
      direction: 'Outbound'
      protocol: 'Tcp'
      sourcePort: '*'
      destinationPort: '*'
      sourceAddress: '*'
      destinationAddress: '*'
    }
  }
}

var varAppliedSettings = {
  network: {
    addressSpaces: config.?addressSpaces ?? [config.?addressSpace ?? varDefaultSettings.network.addressSpace]
  }
}

resource resNetworkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2020-11-01' = [
  for (nsgDefinition, index) in items(config.?nsg ?? {}): {
    // 1. Use the general naming parameters.
    // 2. Provider index, key and location.
    // 3. Use the endpoint specific naming parameters.
    // 4. Use the name property if provided.
    name: name(
      'Microsoft.Network/networkSecurityGroups',
      schema,
      union(
        varNaming,
        {
          index: index + 1
          key: nsgDefinition.key
        },
        nsgDefinition.value.?naming ?? {}
      )
    )
    location: location
    tags: tags

    properties: {
      securityRules: concat(
        map(items(nsgDefinition.value.?inbound ?? {}), rule => {
          name: rule.key

          properties: {
            access: rule.value.access
            direction: varDefaultSettings.networkSecurityRule.inbound.direction
            priority: rule.value.priority
            protocol: rule.value.?protocol ?? varDefaultSettings.networkSecurityRule.inbound.protocol

            sourcePortRange: empty(rule.value.?sourcePorts)
              ? rule.value.?sourcePort ?? varDefaultSettings.networkSecurityRule.inbound.sourcePort
              : null
            destinationPortRange: empty(rule.value.?destinationPorts)
              ? rule.value.?destinationPort ?? varDefaultSettings.networkSecurityRule.inbound.destinationPort
              : null

            sourceAddressPrefix: empty(rule.value.?sourceAddresses)
              ? rule.value.?sourceAddress ?? varDefaultSettings.networkSecurityRule.inbound.sourceAddress
              : null
            destinationAddressPrefix: empty(rule.value.?destinationAddresses)
              ? rule.value.?destinationAddress ?? varDefaultSettings.networkSecurityRule.inbound.destinationAddress
              : null

            sourcePortRanges: rule.value.?sourcePorts
            destinationPortRanges: rule.value.?destinationPorts
            sourceAddressPrefixes: rule.value.?sourceAddresses
            destinationAddressPrefixes: rule.value.?destinationAddresses
          }
        }),
        map(items(nsgDefinition.value.?outbound ?? {}), rule => {
          name: rule.key

          properties: {
            access: rule.value.access
            direction: varDefaultSettings.networkSecurityRule.outbound.direction
            priority: rule.value.priority
            protocol: rule.value.?protocol ?? varDefaultSettings.networkSecurityRule.outbound.protocol

            sourcePortRange: empty(rule.value.?sourcePorts)
              ? rule.value.?sourcePort ?? varDefaultSettings.networkSecurityRule.outbound.sourcePort
              : null
            destinationPortRange: empty(rule.value.?destinationPorts)
              ? rule.value.?destinationPort ?? varDefaultSettings.networkSecurityRule.outbound.destinationPort
              : null

            sourceAddressPrefix: empty(rule.value.?sourceAddresses)
              ? rule.value.?sourceAddress ?? varDefaultSettings.networkSecurityRule.outbound.sourceAddress
              : null
            destinationAddressPrefix: empty(rule.value.?destinationAddresses)
              ? rule.value.?destinationAddress ?? varDefaultSettings.networkSecurityRule.outbound.destinationAddress
              : null

            sourcePortRanges: rule.value.?sourcePorts
            destinationPortRanges: rule.value.?destinationPorts
            sourceAddressPrefixes: rule.value.?sourceAddresses
            destinationAddressPrefixes: rule.value.?destinationAddresses
          }
        })
      )
    }
  }
]
// Directly referencing a resource or module collection is not currently supported here. 
// Apply an array indexer to the expression.bicep(BCP144)
var varNsgArray = [
  for (nsgDefinition, index) in items(config.?nsg ?? {}): {
    index: index + 1
    key: nsgDefinition.key
    id: resNetworkSecurityGroups[index].id
    name: resNetworkSecurityGroups[index].name
  }
]
var varNsgReference = toObject(varNsgArray, entry => entry.key, entry => entry)

output networkSecurityGroup {
  *: {
    id: string
    name: string
  }
} = varNsgReference

/*

  #################################################
  #### Create Virtual Network and Subnets

*/

var varSubnetNames = [
  // 1. Use the general naming parameters.
  // 2. Provider index, key and location.
  // 3. Use the endpoint specific naming parameters.
  // 4. Use the name property if provided.
  for (subnet, index) in items(config.subnet): name(
    'Microsoft.Network/virtualNetworks/subnets',
    schema,
    union(
      varNaming,
      {
        index: index + 1
        key: subnet.key
      },
      subnet.value.?naming ?? {}
    )
  )
]

resource resVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: name('Microsoft.Network/virtualNetworks', schema, varNaming)
  location: location
  tags: tags

  properties: {
    addressSpace: {
      addressPrefixes: varAppliedSettings.network.addressSpaces
    }
    subnets: [
      for (subnet, index) in items(config.subnet): {
        name: varSubnetNames[index]
        properties: {
          addressPrefixes: concat(
            [
              subnet.value.?addressPrefix ?? cidrSubnet(
                varAppliedSettings.network.addressSpaces[0],
                subnet.value.?cidr.?mask ?? varDefaultSettings.network.subnet.cidr,
                index
              )
            ],
            filter([any(subnet.value.?addressPrefixIpv6)], arg => !empty(arg))
          )

          networkSecurityGroup: empty(subnet.value.?securityGroup)
            ? null
            : {
                id: varNsgReference[any(subnet.value.?securityGroup)].id
              }

          serviceEndpoints: map(subnet.value.?serviceEndpoints ?? [], serviceEndpoint => {
            service: serviceEndpoint
          })

          delegations: map(subnet.value.?delegations ?? [], delgation => {
            name: 'default'
            properties: {
              serviceName: delgation
            }
          })
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

var varSubnetArray = [
  for (subnet, index) in items(config.subnet): {
    index: index + 1
    key: subnet.key
    id: format('{0}/subnets/{1}', resVirtualNetwork.id, varSubnetNames[index])
    name: varSubnetNames[index]
  }
]

/*
  Currenty limitations on output via object:

  1. Outputting values from properties of resources: (Bicep CLI version 0.28.1 (ba1e9f8c1e))
    - bicep(BCP247) Using lambda variables inside resource or module array access is not currently supported.
    - bicep(BCP182) [...], which requires values that can be calculated at the start of the deployment. [...]which can be calculated at the start include "apiVersion", "id", "name", "type".
*/

output apiVersion string = resVirtualNetwork.apiVersion
output id string = resVirtualNetwork.id
output name string = resVirtualNetwork.name

output subnet {
  *: {
    id: string
    name: string
    index: int
  }
} = toObject(varSubnetArray, item => item.key, item => item)

/*
    #################################################
    #### Virtual Network Peerings

*/

resource resPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = [
  for (peering, index) in config.?singlePeerings ?? []: {
    parent: resVirtualNetwork
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
          index: index + 1
          sourceVnetName: resVirtualNetwork.name
          remoteVnetName: GetSegmentFromId(peering.remoteVnetId).name
        },
        peering.?source.?naming ?? {}
      )
    )

    properties: {
      remoteVirtualNetwork: {
        id: peering.remoteVnetId
      }

      allowVirtualNetworkAccess: peering.?source.?allowVirtualNetworkAccess ?? varDefaultSettings.peering.allowVirtualNetworkAccess
      allowForwardedTraffic: peering.?source.?allowForwardedTraffic ?? varDefaultSettings.peering.allowForwardedTraffic
      allowGatewayTransit: peering.?source.?allowGatewayTransit ?? varDefaultSettings.peering.allowGatewayTransit
      useRemoteGateways: peering.?source.?useRemoteGateways ?? varDefaultSettings.peering.useRemoteGateways
    }
  }
]

module resPeeringsDual './peering.dual.bicep' = [
  for (peering, index) in config.?dualPeerings ?? []: {
    name: '${subDeploymentName}-peerdual-${index}'
    params: {
      subDeploymentName: '${subDeploymentName}-peerdual-${index}'
      schema: schema
      naming: union(
        {
          index: index + 1
        },
        varNaming
      )
      sourceVnet: {
        id: resVirtualNetwork.id

        naming: peering.?source.?naming

        allowVirtualNetworkAccess: peering.?source.?allowVirtualNetworkAccess ?? varDefaultSettings.peering.allowVirtualNetworkAccess
        allowForwardedTraffic: peering.?source.?allowForwardedTraffic ?? varDefaultSettings.peering.allowForwardedTraffic
        allowGatewayTransit: peering.?source.?allowGatewayTransit ?? varDefaultSettings.peering.allowGatewayTransit
        useRemoteGateways: peering.?source.?useRemoteGateways ?? varDefaultSettings.peering.useRemoteGateways
      }

      remoteVnet: {
        id: peering.remoteVnetId

        naming: peering.?remote.?naming

        allowVirtualNetworkAccess: peering.?remote.?allowVirtualNetworkAccess ?? varDefaultSettings.peering.allowVirtualNetworkAccess
        allowForwardedTraffic: peering.?remote.?allowForwardedTraffic ?? varDefaultSettings.peering.allowForwardedTraffic
        allowGatewayTransit: peering.?remote.?allowGatewayTransit ?? varDefaultSettings.peering.allowGatewayTransit
        useRemoteGateways: peering.?remote.?useRemoteGateways ?? varDefaultSettings.peering.useRemoteGateways
      }
    }
  }
]

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*

  ################################################################################################################################################################################################
  ################################################################################################################################################################################################
  #### EXTENSION RESOURCES AS COMMON PATTERNS ACCROSS MODULES





  
*/

/*

  ###############################################################
  #### EXTENSION RESOURCE: Diagnostic Settings

*/

import { typeDiagnosticSettings, diagnosticUtility } from '../../utility/diagnostic-utility/module.bicep'
param diagnosticSettings typeDiagnosticSettings

resource resDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticSettings)) {
  name: 'diagnosticSettings'
  scope: resVirtualNetwork
  properties: diagnosticUtility(diagnosticSettings, null, null)
}

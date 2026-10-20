@maxLength(50)
@description('''
  This can adjust the name of the sub-deployment.
  Be aware, if the resulting name is longer than 64 characters, the deployment will fail.

  64 - 50 characters for '.avm.pep.X.XX' in the sub deployment.
''')
param subDeploymentPrefix string = length('${deployment().name}.avm.pep.X.XX') > 64
  ? uniqueString(deployment().name)
  : deployment().name

////////////////////////////////////////////////
//// Location and Tags

param location string = resourceGroup().location
param tags {
  *: string
} = {}

////////////////////////////////////////////////
//// Naming Module

import { genNameId, typeNaming } from '../../governance/naming/module.bicep'

@description('Provide a naming schema for name generation.')
param namingSchema object?
@description('Provide a naming id to uniquely identify in the naming schema.')
param namingId string = 'privateEndpoint'
@description('Define any parameters used for name generation here.')
param naming typeNaming?

var useNamingModule = !empty(namingSchema)

@description('''
The name of the private endpoint.
- If a naming schema is provided, this will be added to the parameters of the naming module.
- Otherwise it will be use as the full name of the private endpoint.
''')
param name string?

var varName = useNamingModule
  ? genNameId('Microsoft.Network/privateEndpoints', namingId, namingSchema ?? {}, location, {
      name: name ?? naming.?name
      ...naming ?? {}
    })
  : name ?? fail('If "namingSchema" is not provided, "name" must be provided.')

@description('''
The name of the network interface.
- If a naming schema is provided, this will be added to the parameters of the naming module.
- Otherwise it will be use as the full name of the network interface.
''')
param networkInterfaceName string?

var varNetworkInterfaceName = useNamingModule
  ? genNameId('Microsoft.Network/networkInterfaces', namingId, namingSchema ?? {}, location, {
      name: networkInterfaceName ?? naming.?name
      ...naming ?? {}
    })
  : networkInterfaceName ?? null

////////////////////////////////////////////////
//// Module Parameter

@description('Resource ID of the service to connect to with the private endpoint.')
param resourceId string

import { typePrivateEndpointSubServices } from 'type.members.bicep'
param groupName typePrivateEndpointSubServices = 'default'

@description('Network settings for the private endpoint.')
param network {
  subnetId: string?
  vnet: {
    id: string
    subnet: string
  }?

  staticIP: string?
}

@description('Resource Id of the private DNS zone to use for the private endpoint.')
param privateDnsZoneId string?

@description('DNS settings for the private endpoint.')
param privateDnsZone {
  resourceGroup: string?
  subscriptionId: string?

  @description('If true or `name` is empty, the default private DNS zone for the service will be used. Ignored when `id` is set.')
  useDefault: bool

  @description('Name of the private DNS zone. Ignored when `id` is set.')
  name: string?
}?

@description('Custom DNS configurations for the private endpoint. This is a map of FQDNs to IP addresses.')
param customDnsConfigs {
  *: string[]
} = {}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
////// Failures and Validations

output debug array = varFailChecks
var varFailChecks = map(
  [
    {
      description: 'Either use "privateDnsZoneId" or "privateDnsZone", not both.'
      error: !empty(privateDnsZoneId) && !empty(privateDnsZone)
    }

    {
      description: 'If "privateDnsZone.useDefault" is true, "privateDnsZone.name" must be empty.'
      error: (privateDnsZone.?useDefault ?? false) && !empty(privateDnsZone.?name)
    }

    {
      description: 'The "resourceId" must be a valid resource ID in the format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}'
      error: !contains(resourceId, '/subscriptions/') || !contains(resourceId, '/resourceGroups/')
    }
  ],
  check => !check.error ? check : fail(check.description)
)

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
///// Private Endpoint Resource

import { varMemberReference } from 'var.members.bicep'

////////////////////////////////////////////////

var varTargetProvider = '${split(resourceId, '/')[?6]}/${split(resourceId, '/')[?7]}'

var varMember = varMemberReference[varTargetProvider][groupName]

var varPrivateDnsZone = {
  enable: !empty(privateDnsZoneId) || !empty(privateDnsZone)

  id: privateDnsZoneId ?? format(
    '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/privateDnsZones/{2}',
    privateDnsZone.?subscriptionId ?? subscription().subscriptionId,
    privateDnsZone.?resourceGroup ?? resourceGroup().name,
    (privateDnsZone.?useDefault ?? false) || empty(privateDnsZone.?name) ? varMember.privateDns : privateDnsZone.?name
  )
}

module modPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.11.0' = {
  name: '${subDeploymentPrefix}.avm.pep.0.11'
  params: {
    tags: tags
    location: location

    name: varName
    customNetworkInterfaceName: varNetworkInterfaceName

    subnetResourceId: network.?subnetId ?? format(
      '{0}/subnets/{1}',
      network.?vnet.?id ?? fail('If "subnetId" is not provided, "vnet" must be provided.'),
      network.?vnet.?subnet ?? fail('If "subnetId" is not provided, "vnet" must be provided.')
    )

    //customNetworkInterfaceName: networkinterfaceName
    privateLinkServiceConnections: [
      {
        name: varName
        properties: {
          groupIds: [
            varMember.groupId
          ]
          privateLinkServiceId: resourceId
        }
      }
    ]
    privateDnsZoneGroup: varPrivateDnsZone.enable
      ? {
          name: 'default'
          privateDnsZoneGroupConfigs: [
            {
              name: 'config'
              privateDnsZoneResourceId: varPrivateDnsZone.id
            }
          ]
        }
      : null
    ipConfigurations: !empty(network.?staticIP)
      ? [
          {
            name: 'default'
            properties: {
              groupId: varMember.groupId
              memberName: varMember.groupId
              privateIPAddress: network.?staticIP ?? fail('If "staticIpAddress" is provided, it must not be empty.')
            }
          }
        ]
      : null
    customDnsConfigs: !empty(customDnsConfigs)
      ? map(items(customDnsConfigs ?? {}), item => {
          fqdn: item.key
          ipAddresses: item.value
        })
      : null
  }
}

output id string = modPrivateEndpoint.outputs.resourceId
output name string = modPrivateEndpoint.outputs.name

output privateDomain string = varPrivateDnsZone.enable ? split(varPrivateDnsZone.id, '/')[?8] : ''
output privateUrl string = varPrivateDnsZone.enable ? format('https://{0}', split(varPrivateDnsZone.id, '/')[?8]) : ''

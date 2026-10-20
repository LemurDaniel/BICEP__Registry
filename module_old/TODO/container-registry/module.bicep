////////////////////////////////////////////////
//// Parameters - Naming, Location and Tags

import { typeNamingSchema, genName } from '../../utility/func.name.bicep'

param location string = resourceGroup().location
param tags object = {}

param naming {
  schema: typeNamingSchema
  params: object
  nameid: string?
}

@description('This can adjust the name of the sub-deployment. Will use a unqiue string when name is too long')
param deploymentId string = length(deployment().name) < 30 ? deployment().name : uniqueString(deployment().name)

////////////////////////////////////////////////
//// Parameters - Container Registry

param sku 'Basic' | 'Premium' | 'Standard' = 'Standard'

param adminUser bool = false

param networking {
  access: 'Public' | 'Restricted' | 'Private'?
  bypass: 'AzureServices' | 'None'?
  ipRules: string[]?
}?

var paramNetworking = {
  access: networking.?access ?? 'Public'
  bypass: networking.?bypass ?? 'AzureServices'
  ipRules: networking.?ipRules ?? []
}

param privateEndpoints {
  name: string?
  subnetId: string
  privateDnsZoneId: string?
}[]

////////////////////////////////////////////////
//// Parameters - Container Registry Authentication

param identity {
  systemAssigned: bool?
  userAssigned: string[]?
}?
var paramIdentity = {
  systemAssigned: identity.?systemAssigned ?? false
  userAssigned: identity.?userAssigned ?? []
}

////////////////////////////////////////////////
//// Validations

#disable-next-line no-unused-vars
var validation = map(
  [
    {
      details: 'Advanced Network Settings requires sku "Premium"'
      bool: sku != 'Premium' && paramNetworking.access != 'Public'
    }
    {
      details: 'IP Rules requires sku "Premium"'
      bool: sku != 'Premium' && length(paramNetworking.ipRules) > 0
    }
  ],
  err => err.bool ? fail('ERROR | ${err.details}') : null
)

////////////////////////////////////////////////
//// Module Deployment

module registry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: format('{0}.registry.0.9.1', deploymentId)
  params: {
    name: genName('Microsoft.ContainerRegistry/registries', naming.schema, location, naming.params, {})
    location: location
    tags: tags

    acrSku: sku
    acrAdminUserEnabled: adminUser
    publicNetworkAccess: paramNetworking.access != 'Private' ? 'Enabled' : 'Disabled'
    networkRuleSetDefaultAction: paramNetworking.access == 'Public' ? 'Allow' : 'Deny'
    networkRuleSetIpRules: [
      for ipRule in paramNetworking.ipRules: {
        action: 'Allow'
        value: ipRule
      }
    ]

    managedIdentities: {
      systemAssigned: paramIdentity.systemAssigned
      userAssignedResourceIds: paramIdentity.userAssigned
    }

    exportPolicyStatus: paramNetworking.access != 'Private' ? 'enabled' : 'disabled'

    privateEndpoints: [
      for (endpoint, index) in privateEndpoints: {
        tags: tags
        name: genName(
          'Microsoft.Network/privateEndpoints',
          naming.schema,
          location,
          naming.params,
          { index: index, name: endpoint.?name }
        )
        customNetworkInterfaceName: genName(
          'Microsoft.Network/privateEndpoints/networkInterfaces',
          naming.schema,
          location,
          naming.params,
          { index: index, name: endpoint.?name }
        )

        subnetResourceId: endpoint.subnetId
        privateDnsZoneGroup: empty(endpoint.?privateDnsZoneId)
          ? null
          : {
              privateDnsZoneGroupConfigs: [
                {
                  privateDnsZoneResourceId: any(endpoint.?privateDnsZoneId)
                }
              ]
            }

        customDnsConfigs: []
      }
    ]
  }
}

////////////////////////////////////////////////
//// Outputs - Container Registry

output loginServer string = registry.outputs.loginServer

output resourceId string = registry.outputs.resourceId
output name string = registry.outputs.name

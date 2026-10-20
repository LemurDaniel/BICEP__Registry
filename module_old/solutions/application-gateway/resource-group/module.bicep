////////////////////////////////////////////////
//// Location and Tags

param subDeploymentName string = deployment().name
param location string = 'global'
param tags {
  *: string
} = {}

////////////////////////////////////////////////
//// Naming Module

import { name, nameResourceGroup, typeNaming } from '../../../governance/naming/module.bicep'

@description('Provide a custom naming schema for the resource. Default is used if not provided.')
param schema object
@description('Define any parameters used for name generation here.')
param naming typeNaming
var varNaming = union(naming, {
  location: location
})

////////////////////////////////////////////////
//// Module Parameter

import { configuration } from '../module.types.bicep'
param config configuration

////////////////////////////////////////////////
//// Default Settings

var varDefaultSettings = {
  vnet: {
    addressSpace: '10.0.0.0/24'
  }
}

////////////////////////////////////////////////

/*

  Complete Appication Gateway deployment with KeyVault and Identity

*/

resource resPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: name('Microsoft.Network/publicIPAddresses', schema, varNaming)
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

module modVnet '../../../networking/virtual-network/module.bicep' = {
  name: '${subDeploymentName}-vnet'
  params: {
    diagnosticSettings: config.?virtualNetwork.?diagnosticSettings
    schema: schema
    naming: union(varNaming, config.?virtualNetwork.?naming ?? {})
    location: location
    tags: tags
    config: {
      addressSpace: config.?virtualNetwork.?addressSpace ?? varDefaultSettings.vnet.addressSpace
      subnet: {
        appgateway: empty(config.?virtualNetwork.?subnet.?appgateway.?addressPrefix)
          ? {
              cidr: {
                mask: 24
              }
              serviceEndpoints: [
                'Microsoft.KeyVault'
              ]
            }
          : {
              addressPrefix: config.?virtualNetwork.?subnet.?appgateway.?addressPrefix
              serviceEndpoints: [
                'Microsoft.KeyVault'
              ]
            }
      }

      dualPeerings: config.?virtualNetwork.?dualPeerings ?? []
      singlePeerings: config.?virtualNetwork.?singlePeerings ?? []
    }
  }
}

module modKeyVault '../../../security/key-vault/module.bicep' = {
  name: '${subDeploymentName}-kv'
  params: {
    diagnosticSettings: config.?keyVault.?diagnosticSettings
    schema: schema
    naming: union(varNaming, config.?keyVault.?naming ?? {})
    location: location
    tags: tags
    config: {
      sku: 'standard'
      networkAccess: {
        ipRules: config.?keyVault.?ipRules
        subnetRules: [
          modVnet.outputs.subnet.appgateway.id
        ]
      }
    }
  }
}

module modIdentity '../../../security/identity/module.bicep' = {
  name: '${subDeploymentName}-id'
  params: {
    schema: schema
    naming: union(varNaming, config.?identity.?naming ?? {})
    location: location
    tags: tags
    roleAssignments: [
      {
        resourceId: modKeyVault.outputs.id
        roleDefinitions: [
          'Key Vault Secrets User'
        ]
      }
    ]
  }
}

module modAppGateway '../../../networking/application-gateway/module.bicep' = {
  name: '${subDeploymentName}-appgw'
  params: {
    diagnosticSettings: config.?diagnosticSettings
    schema: schema
    naming: varNaming
    location: location
    tags: tags
    config: {
      sku: config.?sku

      keyVault: {
        id: modKeyVault.outputs.id
        identityId: modIdentity.outputs.id
      }

      network: union(config.?network ?? {}, {
        subnetId: modVnet.outputs.subnet.appgateway.id
        publicIp: {
          id: resPublicIp.id
        }
      })

      backendPool: config.backendPool
      frontendListener: config.frontendListener
      rewriteRuleSet: config.?rewriteRuleSet
    }
  }
}

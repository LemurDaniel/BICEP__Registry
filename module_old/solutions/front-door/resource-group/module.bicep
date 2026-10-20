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

/*

  Complete Frontdoor deployment with KeyVault and Identity

*/

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
        bypass: 'AzureServices'
        defaultAction: 'Deny'
        ipRules: config.keyVault.ipRules
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
          'Key Vault Secrets Officer'
        ]
      }
    ]
  }
}

module modFrontDoor '../../../networking/front-door/module.bicep' = {
  name: '${subDeploymentName}-fd'
  params: {
    diagnosticSettings: config.?diagnosticSettings
    schema: schema
    naming: varNaming
    location: 'global'
    tags: tags
    config: {
      identity: {
        type: 'UserAssigned'
        userAssignedIdentities: [
          modIdentity.outputs.id
        ]
      }

      customerCertificates: {
        keyVaultId: modKeyVault.outputs.id
        certificates: config.?customerCertificates.?certificates ?? {}
      }

      endpoints: config.endpoints
      originGroups: config.originGroups
      ruleSets: config.?ruleSets
    }
  }
}

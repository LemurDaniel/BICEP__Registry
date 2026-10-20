////////////////////////////////////////////////
//// Location and Tags

// param subDeploymentName string = deployment().name
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

param config {
  sku: 'Basic' | 'Classic' | 'Premium' | 'Standard'?

  adminUserEnabled: bool?
  zoneRedundancy: bool?
  publicNetworkAccess: bool?

  networkAccess: {
    bypass: 'AzureServices' | 'None'?
    defaultAction: 'Allow' | 'Deny'?
    ipRules: string[]?
  }?

  anonymousPullEnabled: bool?
  dataEndpointEnabled: bool?

  @description('Supplying 0 will disable the policy.')
  softDeleteDays: int?
  retentionPolicyDays: int?
  trustPolicyType: 'Notary'? // Notary is the only supported value 2024-07

  exportPolicy: bool?
  quarantinePolicy: bool?
  azureADAuthenticationAsArmPolicy: bool?
}

/*

  Deployment of the Azure Container Registry
  
*/

var varDefaultSettings = {
  sku: 'Basic'

  anonymousPullEnabled: false
  dataEndpointEnabled: false
  publicNetworkAccess: true
  adminUserEnabled: false
  zoneRedundancy: false

  networkAccess: {
    bypass: 'AzureServices'
    defaultAction: 'Deny'
    ipRules: []
  }

  softDelete: {
    days: 14
  }

  retentionPolicy: {
    days: 0
  }

  trustPolicy: {
    type: null
  }

  exportPolicy: true
  quarantinePolicy: false
  azureADAuthenticationAsArmPolicy: false
}

resource resRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name('Microsoft.ContainerRegistry/registries', schema, varNaming)

  location: location
  tags: tags
  sku: {
    name: config.?sku ?? varDefaultSettings.sku
  }
  properties: {
    // encryption: {
    //   keyVaultProperties: {
    //     identity: 'string'
    //     keyIdentifier: 'string'
    //   }
    //   status: 'string'
    // }

    anonymousPullEnabled: config.?anonymousPullEnabled ?? varDefaultSettings.anonymousPullEnabled
    dataEndpointEnabled: config.?dataEndpointEnabled ?? varDefaultSettings.dataEndpointEnabled
    adminUserEnabled: config.?adminUserEnabled ?? varDefaultSettings.adminUserEnabled
    publicNetworkAccess: (config.?publicNetworkAccess ?? varDefaultSettings.publicNetworkAccess)
      ? 'Enabled'
      : 'Disabled'
    zoneRedundancy: (config.?zoneRedundancy ?? varDefaultSettings.zoneRedundancy) ? 'Enabled' : 'Disabled'

    networkRuleBypassOptions: config.?networkAccess.?bypass ?? varDefaultSettings.networkAccess.bypass

    // Network Rulesets are allowed on sku Premium
    networkRuleSet: empty(config.?networkAccess)
      ? null
      : {
          defaultAction: config.?networkAccess.?defaultAction ?? varDefaultSettings.networkAccess.defaultAction
          ipRules: map(
            config.?networkAccess.?ipRules ?? varDefaultSettings.networkAccess.ipRules,
            ip =>
              ({
                action: 'Allow'
                value: ip
              })
          )
        }

    policies: {
      azureADAuthenticationAsArmPolicy: {
        status: (config.?azureADAuthenticationAsArmPolicy ?? varDefaultSettings.azureADAuthenticationAsArmPolicy)
          ? 'Enabled'
          : 'Disabled'
      }
      exportPolicy: {
        status: (config.?exportPolicy ?? varDefaultSettings.exportPolicy) ? 'Enabled' : 'Disabled'
      }
      quarantinePolicy: {
        status: (config.?quarantinePolicy ?? varDefaultSettings.quarantinePolicy) ? 'Enabled' : 'Disabled'
      }
      retentionPolicy: {
        status: (config.?retentionPolicyDays ?? varDefaultSettings.retentionPolicy.days) > 0 ? 'Enabled' : 'Disabled'
        days: config.?retentionPolicyDays ?? varDefaultSettings.retentionPolicy.days
      }
      softDeletePolicy: {
        status: (config.?softDeleteDays ?? varDefaultSettings.softDelete.days) > 0 ? 'Enabled' : 'Disabled'
        retentionDays: config.?softDeleteDays ?? varDefaultSettings.softDelete.days
      }
      trustPolicy: {
        status: !empty((config.?trustPolicyType ?? varDefaultSettings.trustPolicy.type)) ? 'Enabled' : 'Disabled'
        type: config.?trustPolicyType ?? varDefaultSettings.trustPolicy.type
      }
    }
  }
}

/*

  #################################################
  #### Module outputs

*/

output type string = resRegistry.type
output id string = resRegistry.id
output name string = resRegistry.name

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
  scope: resRegistry
  properties: diagnosticUtility(diagnosticSettings, null, null)
}

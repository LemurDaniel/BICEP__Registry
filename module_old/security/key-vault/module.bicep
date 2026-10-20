// 64 - 8 characters for '.kv.auth'-Suffix in the sub deployment.
@maxLength(56)
@description('''
  This can adjust the name of the sub-deployment.
  Be aware, if the resulting name is longer than 64 characters, the deployment will fail.

  64 - 8 characters for '.kv.auth'-Suffix in the sub deployment.
''')
param subDeploymentPrefix string = length('${deployment().name}.kv.auth') > 64
  ? uniqueString(deployment().name)
  : deployment().name

////////////////////////////////////////////////
//// Location and Tags

param location string = resourceGroup().location
param tags {
  *: string
} = {}

////////////////////////////////////////////////
//// Parameters - Naming Module

import { genNameId, typeNaming } from '../../governance/naming/module.bicep'

@description('Provide a naming schema for name generation.')
param namingSchema object?
@description('Provide a naming id to uniquely identify in the naming schema.')
param namingId string = 'default'
@description('Define any parameters used for name generation here.')
param naming typeNaming?

var useNamingModule = !empty(namingSchema)

@description('''
The name of the Resource.
- If a naming schema is provided, this will be added to the parameters of the naming module.
- Otherwise it will be use as the full name of the resource.
''')
param name string?

var varName = useNamingModule
  ? genNameId('Microsoft.KeyVault/vaults', namingId, namingSchema ?? {}, location, {
      name: name ?? naming.?name
      ...naming ?? {}
    })
  : name ?? fail('If "namingSchema" is not provided, "name" must be provided.')

////////////////////////////////////////////////
//// Parameters - Key Vault

param sku 'premium' | 'standard' = 'standard'

param createMode 'default' | 'recover' = 'default'

@description('''
  Enable or disable the RBAC authorization model.
  If set to false, the legacy access policies will be used.
''')
param enableRbacAuthorization bool = true
param softDeleteRetentionInDays int = 7

param enabledForDeployment bool = false
param enabledForDiskEncryption bool = false
param enabledForTemplateDeployment bool = false
param enableSoftDelete bool = true

@secure()
@description('In case of cyclic dependencies, use the key-vault-secret module instead.')
param secrets {
  *: {
    value: string
    contentType: string?

    @description('''
      If set to true, the secret will be overwritten if it already exists.
      If set to false, the secret will only be set once!
      Defaults to true.
    ''')
    overwrite: bool?
  }
} = {}

////////////////////////////////////////////////
//// Parameters - Common Network Access

type typeNetworkAccess = {
  access: 'PublicInternet' | 'SelectedNetworksAndIPs' | 'Disabled'
  bypass: 'AzureServices' | 'None'?
  ipRules: string[]?
  subnetRules: string[]?
}?

// Transform the network parameter with default values
// The adjusted variable should be referenced in the module, instead of the original parameter
param network typeNetworkAccess
var paramNetwork = {
  access: network.?access ?? 'PublicInternet'
  bypass: network.?bypass ?? (network.?access == 'Disabled' ? 'None' : 'AzureServices')
  ipRules: network.?ipRules ?? []
  subnetRules: network.?subnetRules ?? []
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
////// Failures and Validations

output debug array = varFailChecks
var varFailChecks = map(
  [
    {
      error: 'ipRules / subnetRules have no effect if access is set to "Disabled"'
      when: paramNetwork.access == 'Disabled' && (length(paramNetwork.ipRules) + length(paramNetwork.subnetRules) > 0)
    }
    {
      error: 'bypass AzureServices has no effect if access is set to "Disabled"'
      when: paramNetwork.access == 'Disabled' && paramNetwork.bypass == 'AzureServices'
    }
  ],
  check => check.when ? fail(check.error) : check
)

////////////////////////////////////////////////
//// Deploy key vault

resource resKeyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: varName
  location: location
  tags: tags
  properties: {
    sku: {
      // Currently only 'A' is possible.
      family: 'A'
      name: sku
    }

    createMode: createMode
    tenantId: subscription().tenantId
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableSoftDelete: enableSoftDelete

    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
    publicNetworkAccess: paramNetwork.access != 'Disabled' ? 'Enabled' : 'Disabled'

    networkAcls: {
      bypass: paramNetwork.bypass
      defaultAction: paramNetwork.access == 'PublicInternet' ? 'Allow' : 'Deny'
      ipRules: [
        for ip in paramNetwork.ipRules: {
          value: ip
        }
      ]
      virtualNetworkRules: [
        for subnet in paramNetwork.subnetRules: {
          id: subnet
        }
      ]
    }
  }
}

var varOverwriteSecrets = filter(items(secrets), s => s.value.?overwrite ?? true)
resource resourceKvSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = [
  for secret in varOverwriteSecrets: {
    parent: resKeyVault
    name: secret.key
    properties: {
      value: secret.value.value
      contentType: secret.value.?contentType
    }
  }
]

var varStaticSecrets = filter(items(secrets), s => !(s.value.?overwrite ?? true))

@onlyIfNotExists()
resource resourceKvStaticSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = [
  for secret in varStaticSecrets: {
    parent: resKeyVault
    name: secret.key
    properties: {
      value: secret.value.value
      contentType: secret.value.?contentType
    }
  }
]

/*

  #################################################
  #### Module outputs

*/

output type string = resKeyVault.type
output id string = resKeyVault.id
output name string = resKeyVault.name

output url string = resKeyVault.properties.vaultUri

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
  scope: resKeyVault
  properties: diagnosticUtility(diagnosticSettings, null, null)
}

/*

  ###############################################################
  #### EXTENSION RESOURCE: Role Assignments

*/

import { typeAsExtensionResource } from '../../security/role-assignment/module.bicep'
param roleAssignments typeAsExtensionResource = []
module modRoleAssignments '../../security/role-assignment/module.bicep' = if (length(roleAssignments) > 0) {
  name: '${subDeploymentPrefix}.kv.auth'
  params: {
    resourceId: resKeyVault.id
    roleAssignments: roleAssignments
  }
}

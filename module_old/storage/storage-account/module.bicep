// 64 - 8 characters for '.st.auth'-Suffix in the sub deployment.
@maxLength(56)
@description('''
  This can adjust the name of the sub-deployment.
  Be aware, if the resulting name is longer than 64 characters, the deployment will fail.

  64 - 8 characters for '.st.auth'-Suffix in the sub deployment.
''')
param subDeploymentPrefix string = length('${deployment().name}.st.auth') > 64
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
  ? genNameId('Microsoft.Storage/storageAccounts', namingId, namingSchema ?? {}, location, {
      name: name ?? naming.?name
      ...naming ?? {}
    })
  : name ?? fail('If "namingSchema" is not provided, "name" must be provided.')

////////////////////////////////////////////////
//// Parameters - Storage Account

@description('The SKU of the Storage Account.')
param kind 'BlobStorage' | 'BlockBlobStorage' | 'FileStorage' | 'Storage' | 'StorageV2' = 'StorageV2'

@description('The access tier of the Storage Account.')
param accessTier 'Hot' | 'Cool' = 'Hot'

@description('The SKU of the Storage Account.')
param sku
  | 'Premium_LRS'
  | 'Premium_ZRS'
  | 'Standard_GRS'
  | 'Standard_GZRS'
  | 'Standard_LRS'
  | 'Standard_RAGRS'
  | 'Standard_RAGZRS'
  | 'Standard_ZRS' = 'Standard_LRS'

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

////////////////////////////////////////////////
//// Parameters - Subservices

param allowBlobPublicAccess bool = false
param allowCrossTenantReplication bool = false
param allowSharedKeyAccess bool = false
param supportsHttpsTrafficOnly bool = true
param defaultToOAuthAuthentication bool = false

param fileshare {
  *: {
    name: string
    quota: int
    accessTier: 'Cool' | 'Hot' | 'Premium' | 'TransactionOptimized'?
    protocol: 'SMB' | 'NFS'?
    rootSquash: 'AllSquash' | 'NoRootSquash' | 'RootSquash'?
  }
} = {}

param container {
  *: 'Container' | 'Blob' | 'Private'
} = {}

param queue string[] = []
param table string[] = []

////////////////////////////////////////////////
//// Default Settings

var varDefaultSettings = {
  fileshare: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
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
//// Deploy Storage Account

resource resAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: varName

  location: location
  tags: tags

  kind: kind
  sku: {
    name: sku
  }

  properties: {
    publicNetworkAccess: paramNetwork.access != 'Disabled' ? 'Enabled' : 'Disabled'

    accessTier: accessTier

    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    minimumTlsVersion: 'TLS1_2'

    networkAcls: {
      bypass: paramNetwork.bypass
      defaultAction: paramNetwork.access == 'PublicInternet' ? 'Allow' : 'Deny'
      ipRules: [
        for rule in paramNetwork.ipRules: {
          value: rule
        }
      ]
      virtualNetworkRules: [
        for subnet in paramNetwork.subnetRules: {
          id: subnet
        }
      ]
    }
  }

  resource resFileShare 'fileServices@2024-01-01' = {
    name: 'default'
  }

  resource resBlobService 'blobServices@2024-01-01' = {
    name: 'default'
  }

  resource resTableService 'tableServices@2024-01-01' = {
    name: 'default'
  }

  resource resQueueService 'queueServices@2024-01-01' = {
    name: 'default'
  }
}

output id string = resAccount.id
output name string = resAccount.name
output properties object = resAccount.properties

@secure()
output credentials object = {
  primaryAccessKey: resAccount.listKeys().keys[0].value
  secondaryAccessKey: resAccount.listKeys().keys[1].value

  primaryConnectionString: format(
    'DefaultEndpointsProtocol=https;AccountName={0};EndpointSuffix={1};AccountKey={2}',
    resAccount.name,
    environment().suffixes.storage,
    resAccount.listKeys().keys[0].value
  )
  secondaryConnectionString: format(
    'DefaultEndpointsProtocol=https;AccountName={0};EndpointSuffix={1};AccountKey={2}',
    resAccount.name,
    environment().suffixes.storage,
    resAccount.listKeys().keys[1].value
  )
}

/*

  ////////////////////////////////////////////////
  //// File shares

*/

resource resFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-06-01' = [
  for share in items(fileshare): {
    parent: resAccount::resFileShare
    name: share.value.name
    properties: {
      shareQuota: share.value.quota
      rootSquash: share.value.?rootSquash
      accessTier: share.value.?accessTier ?? varDefaultSettings.fileshare.accessTier
      enabledProtocols: share.value.?protocol ?? varDefaultSettings.fileshare.enabledProtocols
    }
  }
]

var varFileShareArray = [
  for (share, index) in items(fileshare): {
    index: index
    key: share.key
    id: resFileShare[index].id
    name: resFileShare[index].name
  }
]

output fileshare {
  *: {
    id: string
    name: string
    index: int
  }
} = toObject(varFileShareArray, item => item.key, item => item)

/*

  ////////////////////////////////////////////////
  //// Blob container

*/

resource resContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = [
  for container in items(container): {
    parent: resAccount::resBlobService
    name: container.key
    properties: {
      publicAccess: {
        Container: 'Container'
        Blob: 'Blob'
        Private: 'None'
      }[container.value]
    }
  }
]

var varContainerArray = [
  for (container, index) in items(container): {
    index: index
    key: container.key
    id: resContainer[index].id
    name: resContainer[index].name
  }
]

output container {
  *: {
    id: string
    name: string
    index: int
  }
} = toObject(varContainerArray, item => item.key, item => item)

/*

  ////////////////////////////////////////////////
  //// Tables

*/

resource resTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-06-01' = [
  for table in table: {
    parent: resAccount::resTableService
    name: table
  }
]

var varTableArray = [
  for (table, index) in table: {
    index: index
    key: table
    id: resTable[index].id
    name: resTable[index].name
  }
]

output table {
  *: {
    id: string
    name: string
    index: int
  }
} = toObject(varTableArray, item => item.key, item => item)

/*

  ////////////////////////////////////////////////
  //// Queue

*/

resource resQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-06-01' = [
  for queue in queue: {
    parent: resAccount::resQueueService
    name: queue
  }
]

var varQueueArray = [
  for (queue, index) in queue: {
    index: index
    key: queue
    id: resQueue[index].id
    name: resQueue[index].name
  }
]

output queue {
  *: {
    id: string
    name: string
    index: int
  }
} = toObject(varQueueArray, item => item.key, item => item)

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
  scope: resAccount
  properties: diagnosticUtility(diagnosticSettings, null, null)
}

/*

  ###############################################################
  #### EXTENSION RESOURCE: Role Assignments

*/

import { typeAsExtensionResource } from '../../security/role-assignment/module.bicep'
param roleAssignments typeAsExtensionResource = []
module modRoleAssignments '../../security/role-assignment/module.bicep' = if (length(roleAssignments) > 0) {
  name: '${subDeploymentPrefix}.st.auth'
  params: {
    resourceId: resAccount.id
    roleAssignments: roleAssignments
  }
}

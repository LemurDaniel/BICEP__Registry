// 64 - 8 characters for '.kv.auth'-Suffix in the sub deployment.
@maxLength(60)
@description('''
  This can adjust the name of the sub-deployment.
  Be aware, if the resulting name is longer than 64 characters, the deployment will fail.

  64 - 4 characters for '.app'-Suffix in the sub deployment.
''')
param subDeploymentPrefix string = length('${deployment().name}.app') > 64
  ? uniqueString(deployment().name)
  : deployment().name

////////////////////////////////////////////////
//// Parameters - Naming Module

import { genNameId, typeNaming } from '../../modules/utility/naming/generator/module.bicep'

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
//// Location and Tags

param location string = resourceGroup().location
param tags {
  *: string
} = {}

////////////////////////////////////////////////
//// Parameters - Container Registry Authentication

param identity {
  systemAssigned: bool?
  userAssigned: string[]?
}?
var paramIdentity = {
  systemAssigned: identity.?systemAssigned ?? false
  userAssigned: any(identity.?userAssigned) ?? []
}

////////////////////////////////////////////////
//// Parameters - App Service

param servicePlanId string

param kind 'App' | 'FunctionApp' | 'WorkflowApp' = 'App'

////////////////////////////////////////////////
//// Parameters - App Service Networking

param networking {
  access: 'Public' | 'Restricted' | 'Private'?
  bypass: 'AzureServices' | 'None'?
  ipRules: {
    ipAddress: string?
    serviceTag: string?
    priority: int?
    action: 'Allow' | 'Deny'?
    description: string?
  }[]?
}?

var ipSecurityRestrictions = [
  for (ipRule, index) in (networking.?ipRules ?? []): {
    action: ipRule.?action ?? 'Allow'
    description: ipRule.?description ?? 'Deployed via Bicep | ${ipRule.?ipAddress ?? ipRule.?serviceTag}'
    tag: !empty(ipRule.?serviceTag) ? 'ServiceTag' : 'Default'
    ipAddress: !empty(ipRule.?serviceTag)
      ? ipRule.?serviceTag
      : (contains(ipRule.?ipAddress, '/') ? ipRule.?ipAddress : '${ipRule.?ipAddress}/32')
    priority: ipRule.?priority ?? (index * 10 + 1000) // Default priority starts at 1000 and increments by 10 for each rule
  }
]

var paramNetworking = {
  access: networking.?access ?? 'Public'
  bypass: networking.?bypass ?? 'AzureServices'
  ipRestrictions: {
    ipSecurityRestrictionsDefaultAction: networking.?access == 'Private' ? 'Deny' : 'Allow'
    ipSecurityRestrictions: ipSecurityRestrictions

    scmIpSecurityRestrictionsDefaultAction: networking.?access == 'Private' ? 'Deny' : 'Allow'
    scmIpSecurityRestrictions: ipSecurityRestrictions
  }
}

////////////////////////////////////////////////
//// Parameters - App Service Runtime

import { getKind } from './func.kind.bicep'
import { typeRuntime as import_typeRuntime, getRuntimeConfig } from './func.runtime.bicep'

@export()
type typeRuntime = import_typeRuntime
param runtime typeRuntime

@description('''
Set environment variables for the app service.
Example:
{
  SOME_ENV: False
  .
  .
  .
}
''')
param environment object = {}

@description('''
Site configs are automatically generated based on the runtime type.
Override any of those values via the `siteConfigs` parameter.
''')
param siteConfig object = {}

resource resAppServicePlan 'Microsoft.Web/serverfarms@2023-01-01' existing = {
  name: last(split(servicePlanId, '/'))
}

var varSiteConfigDefaults = {
  alwaysOn: resAppServicePlan.sku != 'F1'
  ftpsState: 'FtpsOnly'
  minTlsVersion: '1.2'
  httpsOnly: true

  hostingEnvironmentProfile: null
  hostNameSslStates: null
  hyperV: false
}

var varRuntimeConfig = getRuntimeConfig(runtime)

var varSiteConfig = union(
  // Default site configs
  varSiteConfigDefaults,
  // Default configuration for current Runtime
  varRuntimeConfig.siteconfig,
  // Custom site configs via parameter
  siteConfig,
  {
    ipRestrictions: paramNetworking.ipRestrictions
    appSettings: map(
      items(union(
        // Runtime app settings
        varRuntimeConfig.appSettings,
        // Environment Variables
        environment
      )),
      env => {
        name: env.key
        value: env.value
      }
    )
  }
)

////////////////////////////////////////////////
//// Validations

#disable-next-line no-unused-vars
var validation = map(
  [
    {
      details: 'Only one runtime type can be specified'
      bool: length(items(runtime)) > 1
    }
  ],
  err => err.bool ? fail('ERROR | ${err.details}') : null
)

////////////////////////////////////////////////
//// Deployment - App Service

module modWebApp 'br/public:avm/res/web/site:0.19.0' = {
  name: format('{0}.site.0.19.0', subDeploymentPrefix)
  params: {
    name: varName
    location: location
    tags: tags
    kind: getKind(runtime, resAppServicePlan.kind, kind)

    serverFarmResourceId: servicePlanId

    managedIdentities: {
      systemAssigned: paramIdentity.systemAssigned
      userAssignedResourceIds: paramIdentity.userAssigned
    }

    publicNetworkAccess: paramNetworking.access != 'Private' ? 'Enabled' : 'Disabled'

    siteConfig: varSiteConfig
  }
}

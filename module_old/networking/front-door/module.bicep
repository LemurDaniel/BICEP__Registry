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

import { configuration } from 'module.types.bicep'
param config configuration

////////////////////////////////////////////////

/*

  Default settings

*/

var varDefaultSettings = {
  sku: 'Standard_AzureFrontDoor'
}

/*

  CDN Profile

*/

resource resCDNProfile 'Microsoft.Cdn/profiles@2024-02-01' = {
  name: name('Microsoft.Cdn/profiles', schema, varNaming)
  location: location
  tags: tags
  sku: {
    name: config.?sku ?? varDefaultSettings.sku
  }
  identity: empty(config.?identity.?type)
    ? null
    : {
        type: any(config.?identity.?type)
        userAssignedIdentities: empty(config.?identity.?userAssignedIdentities)
          ? null
          : toObject(config.?identity.?userAssignedIdentities ?? [], arg => arg, arg => {})
      }
}

/*

  CDN origins e.g. the backend where frontdoor directs traffic to.

*/

module modOriginGroup './module.origin.bicep' = [
  for (originGroup, index) in items(config.originGroups): {
    name: format(
      '{0}-{1}-og',
      subDeploymentName,
      substring(uniqueString(originGroup.key), 0, 4)
    )
    params: {
      schema: schema

      // 1. Use the general naming parameters.
      // 2. Provider index, key and location.
      // 3. Use the endpoint specific naming parameters.
      // 4. Use the name property if provided.
      naming: union(
        varNaming,
        {
          index: index + 1
          key: originGroup.key
          location: location
        },
        originGroup.value.?naming ?? {}
      )

      location: location
      profileName: resCDNProfile.name
      identifierKey: originGroup.key
      config: originGroup.value
    }
  }
]

/*

  CDN RuleSets

*/

module modRuleSet 'module.ruleset.bicep' = [
  for (ruleSet, index) in items(config.?ruleSets ?? {}): {
    name: format('{0}-{1}-rs', subDeploymentName, substring(uniqueString(ruleSet.key), 0, 4))
    params: {
      schema: schema

      // 1. Use the general naming parameters.
      // 2. Provider index, key and location.
      // 3. Use the endpoint specific naming parameters.
      // 4. Use the name property if provided.
      naming: union(
        varNaming,
        {
          index: index + 1
          key: ruleSet.key
          location: location
        },
        ruleSet.value.?naming ?? {}
      )

      profileName: resCDNProfile.name
      identifierKey: ruleSet.key
      config: ruleSet.value
    }
  }
]

/*

  CDN Endpoint e.g. the entry point for requests to the CDN.

*/

module modEndpoint './module.endpoint.bicep' = [
  for (endpoint, index) in items(config.endpoints): {
    name: format('{0}-{1}-fde', subDeploymentName, substring(uniqueString('${index}'), 0, 4))
    params: {
      schema: schema

      // 1. Use the general naming parameters.
      // 2. Provider index, key and location.
      // 3. Use the endpoint specific naming parameters.
      // 4. Use the name property if provided.
      naming: union(
        varNaming,
        {
          index: index + 1
          key: endpoint.key
          location: location
        },
        endpoint.value.?naming ?? {}
      )

      location: location
      profileName: resCDNProfile.name

      ruleSetReference: [
        for (ruleSet, index) in items(config.?ruleSets ?? {}): {
          id: modRuleSet[index].outputs.id
          key: modRuleSet[index].outputs.key
        }
      ]

      originGroupReference: [
        for (originGroup, index) in items(config.originGroups): {
          id: modOriginGroup[index].outputs.id
          key: modOriginGroup[index].outputs.key
        }
      ]

      /// This needs to filter out the naming and name properties, since routes are defined on the same level.
      config: toObject(
        filter(items(endpoint.value), route => !contains(['naming', 'name'], route.key)),
        route => route.key,
        route => route.value
      )
    }
  }
]

/*

TODO: Create and use WAF-Module for associations.

DO NOT USE: Microsoft.Cdn/cdnWebApplicationFirewallPolicies@2023-07-01-preview IT IS BEING RETIRED

resource symbolicname 'Microsoft.Cdn/profiles/securityPolicies@2023-07-01-preview' = {
  name: 'string'
  parent: resourceSymbolicName
  properties: {
    parameters: {
      type: 'string'
      // For remaining properties, see SecurityPolicyPropertiesParameters objects
    }
  }
}


TODO: Custom domain support
*/

resource resSecret 'Microsoft.Cdn/profiles/secrets@2024-05-01-preview' = [
  for (certificate, index) in items(config.?customerCertificates.?certificates ?? {}): {
    parent: resCDNProfile
    name: replace(certificate.key, '.', '-')
    properties: {
      parameters: {
        type: 'CustomerCertificate'
        secretSource: {
          id: any(format('{0}/secrets/{1}', config.?customerCertificates.?keyVaultId, certificate.value.secretName))
        }
        secretVersion: certificate.value.?secretVersion
        useLatestVersion: empty(certificate.value.?secretVersion)
        subjectAlternativeNames: concat([certificate.key], certificate.value.?alternateNames ?? [])
      }
    }
  }
]

/*

  #################################################
  #### Module outputs

*/

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
  scope: resCDNProfile
  properties: diagnosticUtility(diagnosticSettings, null, null)
}

/*

  ###############################################################
  #### EXTENSION RESOURCE: Role Assignments

*/

import { typeUtilityRoleAssignments, uniqueRoles, uniqueAssignments, builtInRole } from '../../utility/role-utility/module.bicep'
param roleAssignments typeUtilityRoleAssignments

resource resRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = [
  for (role, index) in uniqueRoles(roleAssignments): {
    name: builtInRole[role]
  }
]
resource resRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (assignment, index) in uniqueAssignments(roleAssignments, resourceGroup().id): {
    scope: resCDNProfile
    name: assignment.name
    properties: {
      principalId: assignment.principalId
      roleDefinitionId: resRoleDefinition[assignment.roleIndex].id
    }
  }
]


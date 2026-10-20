////////////////////////////////////////////////
//// Location and Tags

// param subDeploymentName string = deployment().name
param location string = 'global'
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

param ruleSetReference {
  key: string
  id: string
}[]

param originGroupReference {
  key: string
  id: string
}[]

@description('The name of the cdn profile.')
param profileName string

import { endpointRoute } from './module.types.bicep'
param config {
  *: endpointRoute
}

////////////////////////////////////////////////
//// Default Settings

var varDefaultSettings = {
  route: {
    name: 'default'
    originPath: '/'
    enableDefaultDomain: true
    patternsToMatch: [
      '/*'
    ]
    httpsRedirect: true
    forwardingProtocol: 'MatchRequest'
    supportedProtocols: 'Http;Https'

    caching: {
      enabled: true
      behavior: 'UseQueryString'
      queryParameters: null
      compression: false
    }
  }
}

////////////////////////////////////////////////

/*

  CDN Profile

*/

resource resCDNProfile 'Microsoft.Cdn/profiles@2023-07-01-preview' existing = {
  name: profileName
}

/*

  CDN Endpoint e.g. the entry point for requests to the CDN.

*/

resource resEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-07-01-preview' = {
  parent: resCDNProfile
  name: name('Microsoft.Cdn/profiles/afdEndpoints', schema, varNaming)
  location: location
  tags: tags
  properties: {}
}

var varRuleSetsReference = toObject(ruleSetReference, ruleSet => ruleSet.key, ruleSet => ruleSet)
var varOriginGroupsReference = toObject(
  originGroupReference,
  originGroup => originGroup.key,
  originGroup => originGroup
)

resource resRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-07-01-preview' = [
  for route in items(config): {
    parent: resEndpoint
    name: route.value.?name ?? varDefaultSettings.route.name
    properties: {
      originGroup: {
        id: any(varOriginGroupsReference[route.value.originGroup].id)
      }
      enabledState: route.value.?disable ?? false ? 'Disabled' : 'Enabled'
      linkToDefaultDomain: (route.value.?enableDefaultDomain ?? varDefaultSettings.route.enableDefaultDomain)
        ? 'Enabled'
        : 'Disabled'
      originPath: route.value.?originPath ?? varDefaultSettings.route.originPath
      patternsToMatch: concat([route.key], route.value.?additonalPatterns ?? [])
      httpsRedirect: (route.value.?httpsRedirect ?? varDefaultSettings.route.httpsRedirect) ? 'Enabled' : 'Disabled'
      forwardingProtocol: route.value.?forwardingProtocol ?? varDefaultSettings.route.forwardingProtocol
      supportedProtocols: split(route.value.?supportedProtocols ?? varDefaultSettings.route.supportedProtocols, ';')
      cacheConfiguration: !(route.value.?caching.?enabled ?? varDefaultSettings.route.caching.enabled)
        ? null
        : {
            queryStringCachingBehavior: route.value.?caching.?behavior ?? varDefaultSettings.route.caching.behavior
            queryParameters: empty(route.value.?caching.?queryParameters ?? varDefaultSettings.route.caching.queryParameters)
              ? null
              : join(
                  route.value.?caching.?queryParameters ?? varDefaultSettings.route.caching.queryParameters ?? [],
                  ','
                )
            compressionSettings: {
              isCompressionEnabled: route.value.?caching.?compression ?? varDefaultSettings.route.caching.compression
              //    contentTypesToCompress: [
              //      'string'
              //    ]
            }
          }
      ruleSets: concat(
        // Handle the case where multiple ruleSets are provided via the multiple ruleSets property.
        map(route.value.?ruleSets ?? [], ruleSet => {
          id: varRuleSetsReference[ruleSet].id
        }),
        // Handle the case where a single ruleSet is provided via the single ruleSet property.
        map(empty(route.value.?ruleSet) ? [] : [route.value.?ruleSet], ruleSet => {
          id: varRuleSetsReference[ruleSet].id
        })
      )
      //customDomains: [
      //  {
      //    id: 'string'
      //  }
      //]
    }
  }
]

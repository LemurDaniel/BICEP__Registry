////////////////////////////////////////////////
//// Location and Tags

// param subDeploymentName string = deployment().name
param location string = 'global'
// param tags {
//   *: string
// } = {}

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

@description('The name of the cdn profile.')
param profileName string
@description('The identifier key for cross-referencing the resource.')
param identifierKey string

import { ruleSet } from './module.types.bicep'
param config ruleSet

////////////////////////////////////////////////
//// Default settings

var varDefaultSettings = {
  matchProcessingBehavior: 'Continue'
  ModifyRequestHeader: {
    headerAction: 'Overwrite'
    header: ''
    value: ''
  }
  ModifyResponseHeader: {
    headerAction: 'Overwrite'
    header: ''
    value: ''
  }
  OriginGroupOverride: {
    originGroup: ''
  }
  AfdUrlSigning: {
    algoritm: 'SHA256'
    keyGroup: 'default'
  }
  CacheExpiration: {
    behavior: 'Override'
    duration: '00:05:00'
    type: 'All'
  }
  CacheKeyQueryString: {
    behavior: 'Include'
    queryParameters: []
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

  CDN origins e.g. the backend where frontdoor directs traffic to.

*/

resource resRuleSet 'Microsoft.Cdn/profiles/ruleSets@2020-09-01' = {
  parent: resCDNProfile
  name: name('Microsoft.Cdn/profiles/ruleSets', schema, varNaming)
}

resource resRule 'Microsoft.Cdn/profiles/ruleSets/rules@2020-09-01' = [
  for (rule, index) in config.rules: {
    parent: resRuleSet
    name: rule.name
    properties: {
      order: index + 1
      matchProcessingBehavior: config.?matchProcessingBehavior ?? varDefaultSettings.matchProcessingBehavior
      actions: concat(
        map(items(rule.?ModifyRequestHeaders ?? {}), action => {
          name: 'ModifyRequestHeader'
          parameters: {
            typeName: 'DeliveryRuleHeaderActionParameters'
            headerAction: action.value.?headerAction ?? varDefaultSettings.ModifyRequestHeader.headerAction
            headerName: action.key
            value: action.value.headerValue
          }
        }),
        map(items(rule.?ModifyResponseHeaders ?? {}), action => {
          name: 'ModifyResponseHeader'
          parameters: {
            typeName: 'DeliveryRuleHeaderActionParameters'
            headerAction: action.value.?headerAction ?? varDefaultSettings.ModifyRequestHeader.headerAction
            headerName: action.key
            value: action.value.headerValue
          }
        }),
        empty(rule.?CacheExpiration)
          ? []
          : [
              {
                name: 'CacheExpiration'
                parameters: {
                  typeName: 'DeliveryRuleCacheExpirationActionParameters'
                  cacheBehavior: rule.?CacheExpiration.behavior
                  cacheDuration: rule.?CacheExpiration.duration
                  cacheType: varDefaultSettings.CacheExpiration.type
                }
              }
            ],
        empty(rule.?CacheKeyQueryString)
          ? []
          : [
              {
                name: 'CacheKeyQueryString'
                parameters: {
                  typeName: 'DeliveryRuleCacheKeyQueryStringBehaviorActionParameters'
                  queryParameters: join(rule.?CacheKeyQueryString.queryParameters ?? [], ',')
                  queryStringBehavior: rule.?CacheKeyQueryString.behavior
                }
              }
            ],
        empty(rule.?OriginGroupOverride)
          ? []
          : [
              {
                name: 'OriginGroupOverride'
                parameters: {
                  typeName: 'DeliveryRuleOriginGroupOverrideActionParameters'
                  originGroup: {
                    id: any(rule.?OriginGroupOverride.originGroup.id)
                  }
                }
              }
            ]
      )
    }
  }
]

output apiVersion string = resRuleSet.apiVersion
output key string = identifierKey
output id string = resRuleSet.id
output name string = resRuleSet.name

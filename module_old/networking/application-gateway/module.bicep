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

import { configuration } from 'module.types.bicep'
param config configuration

////////////////////////////////////////////////
//// Default settings

var varDefaultSettings = {
  sku: {
    name: 'Standard_v2'
    tier: 'Standard_v2'
    capacity: 1
  }

  listener: {
    redirect: {
      includePath: true
      includeQueryString: true
    }
  }

  backend: {
    requestTimeout: 20
    drainTimeoutInSec: 60

    healthProbe: {
      interval: 30
      timeout: 30
      unhealthyThreshold: 3
      minHealthyBackend: 1
    }
  }

  rewriteRule: {
    condition: {
      ignoreCase: false
      negate: false
    }
    requestHeader: {
      ignoreCase: false
      negate: false
      pattern: null
    }
    responseHeader: {
      ignoreCase: false
      negate: false
      pattern: null
    }
  }
}

////////////////////////////////////////////////

/*

  This converts the input to deploy http and https listeners to two separate listeners.

*/

var varBackendPool = toObject(
  flatten(map(
    items(config.backendPool),
    pool =>
      pool.value.protocol == 'Http&Https'
        ? [
            {
              key: '${pool.key}-http'
              value: union(pool.value, {
                protocol: 'Http'
              })
            }
            {
              key: '${pool.key}-https'
              value: union(pool.value, {
                protocol: 'Https'
              })
            }
          ]
        : [
            {
              key: '${pool.key}-${toLower(pool.value.protocol)}'
              value: pool.value
            }
          ]
  )),
  pool => pool.key,
  pool => pool.value
)

/*

  Defining all naming conventions for the resources.

  This is required for inter-referencing resources in the application gateway definition.

*/

var varNamingRef = {
  // These names must be inter-referenced in the application gateway definition, via resource id.
  applicationGateway: name('Microsoft.Network/applicationGateways', schema, varNaming)

  ipConfig: {
    gateway: 'gateway-subnet-config'
    public: 'public-frontend-ip'
    private: 'private-frontend-ip'
  }

  certificate: 'cert-{0}'
  healthProbe: 'probe-{0}'
  backendPool: 'pool-{0}'
  backendSettings: 'settings-{0}'
  httpListener: 'listener-{0}'
  routingRule: 'rule-{0}'
  urlPathMap: 'pathmap-{0}'
  rewriteRule: 'rewrite-{0}'
  redirect: 'redirect-{0}'
}

/*

  Define the application gateway.

*/

var varKeyVault = {
  dnsName: environment().suffixes.keyvaultDns
  name: split(config.?keyVault.?id ?? '/', '/')[?8]
}

resource resAppGateway 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: varNamingRef.applicationGateway
  location: location
  tags: tags
  identity: empty(config.?keyVault)
    ? null
    : {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${config.?keyVault.?identityId}': {}
        }
      }

  properties: {
    sku: {
      name: config.?sku.?name ?? varDefaultSettings.sku.name
      tier: config.?sku.?tier ?? varDefaultSettings.sku.tier
      capacity: config.?sku.?capacity ?? varDefaultSettings.sku.capacity
    }

    ////////////////////////////////////////////////
    /*
    
      The subnet that is used for the application gateway.

    */
    gatewayIPConfigurations: [
      {
        name: varNamingRef.ipConfig.gateway
        properties: {
          subnet: {
            id: config.network.subnetId
          }
        }
      }
    ]

    ////////////////////////////////////////////////
    ////////////////////////////////////////////////
    /*
    

      The backend configuration:
      - backend address pool
      - backend health probes
      - backend settings

    */
    backendAddressPools: map(items(varBackendPool), pool => {
      name: format(varNamingRef.backendPool, pool.key)
      properties: {
        // Combine all entered fqdns and ips into a single array of backend addresses.
        backendAddresses: concat(
          map(pool.value.?fqdns ?? [], fqdn => {
            fqdn: fqdn
          }),
          map(pool.value.?ips ?? [], ip => {
            ipAddress: ip
          }),
          // Support for single fqdn and ip when calling the module.
          map(!empty(pool.value.?fqdn) ? [pool.value.?fqdn] : [], fqdn => {
            fqdn: fqdn
          }),
          map(!empty(pool.value.?ip) ? [pool.value.?ip] : [], fqdn => {
            fqdn: fqdn
          })
        )
      }
    })

    probes: map(filter(items(varBackendPool), pool => pool.value.?healthPrope.?enabled ?? true), pool => {
      name: format(varNamingRef.healthProbe, pool.key)
      properties: {
        // Use the port from the health probe, otherwise use the port from the backend pool or infer the port from the protocol.
        port: (pool.value.?healthPrope.?port) ?? (pool.value.?port) ?? (pool.value.protocol == 'Http' ? 80 : 443)

        protocol: pool.value.protocol

        path: (pool.value.?healthPrope.?path) ?? '/'

        minServers: (pool.value.?healthPrope.?minHealthyBackend) ?? varDefaultSettings.backend.healthProbe.minHealthyBackend
        interval: (pool.value.?healthPrope.?interval) ?? varDefaultSettings.backend.healthProbe.interval
        timeout: (pool.value.?healthPrope.?timeout) ?? varDefaultSettings.backend.healthProbe.timeout
        unhealthyThreshold: (pool.value.?healthPrope.?unhealthyThreshold) ?? varDefaultSettings.backend.healthProbe.unhealthyThreshold

        host: pool.value.?healthPrope.?host ?? pool.value.?override.?hostName
        // pickHostNameFromBackendSettings: bool ???
        pickHostNameFromBackendHttpSettings: empty(pool.value.?healthPrope.?host) && empty(pool.value.?override.?hostName)

        match: empty(pool.value.?healthPrope.?condition)
          ? {}
          : {
              body: pool.value.?healthPrope.?condition.?body
              statusCodes: pool.value.?healthPrope.?condition.?statusCodes
            }
      }
    })

    backendHttpSettingsCollection: map(items(varBackendPool), pool => {
      name: format(varNamingRef.backendSettings, pool.key)
      properties: {
        port: pool.value.?port ?? (pool.value.protocol == 'Http' ? 80 : 443)
        protocol: pool.value.protocol

        path: pool.value.?override.?path
        hostName: pool.value.?override.?hostName
        pickHostNameFromBackendAddress: empty(pool.value.?override.?hostName)

        cookieBasedAffinity: empty(pool.value.?affinityCookieName) ? 'Disabled' : 'Enabled'
        affinityCookieName: pool.value.?affinityCookieName

        requestTimeout: pool.value.?requestTimeout
        connectionDraining: {
          enabled: (pool.value.?drainTimeoutInSec ?? 0) > 0
          drainTimeoutInSec: pool.value.?drainTimeoutInSec ?? varDefaultSettings.backend.drainTimeoutInSec
        }

        probeEnabled: !(pool.value.?healthPrope.?enabled ?? true)
        probe: !(pool.value.?healthPrope.?enabled ?? true)
          ? null
          : {
              id: resourceId(
                'Microsoft.Network/applicationGateways/probes',
                varNamingRef.applicationGateway,
                format(varNamingRef.healthProbe, pool.key)
              )
            }

        //authenticationCertificates: [
        //  {
        //    id: 'string'
        //  }
        //]
        //trustedRootCertificates: [
        //  {
        //    id: 'string'
        //  }
        //]
      }
    })

    ////////////////////////////////////////////////
    ////////////////////////////////////////////////
    /*


      The frontend configuration:
      - frontend IPs private or public
      - frontent ssl-certificates
      - frontent listeners
      - frontent ports

    */
    frontendIPConfigurations: filter(
      [
        // Conditionally add the public IP configuration if it is provided.
        empty(config.network.?publicIp.?id)
          ? {}
          : {
              name: varNamingRef.ipConfig.public
              properties: {
                publicIPAddress: {
                  id: config.network.?publicIp.?id
                }
              }
            }

        // Conditionally add the private IP configuration if it is provided.
        empty(config.?network.?privateIp)
          ? {}
          : {
              name: varNamingRef.ipConfig.private
              properties: {
                privateIPAllocationMethod: 'Static'
                privateIPAddress: config.?network.?privateIp
              }
            }
      ],
      item => !empty(item)
    )

    sslCertificates: map(
      // There is no distinct-function in bicep. (version 0.28.1)
      // Getting distinct certificates can also be achieved by using union over the same array.
      union(
        map(
          filter(items(config.frontendListener), arg => !empty(arg.value.?SSLCertificate)),
          arg => arg.value.?SSLCertificate
        ),
        map(
          filter(items(config.frontendListener), arg => !empty(arg.value.?SSLCertificate)),
          arg => arg.value.?SSLCertificate
        )
      ),
      uniqueCertificate => {
        name: format(varNamingRef.certificate, uniqueCertificate)
        properties: {
          keyVaultSecretId: format(
            'https://{0}.{1}/secrets/{2}',
            varKeyVault.name,
            varKeyVault.dnsName,
            uniqueCertificate,
            'latest'
          )
        }
      }
    )

    frontendPorts: map(
      // There is no distinct-function in bicep. (version 0.28.1)
      // Getting distinct ports can also be achieved by using union over the same array.
      union(
        map(items(config.frontendListener), arg => arg.value.?port ?? (arg.value.protocol == 'Http' ? 80 : 443)),
        map(items(config.frontendListener), arg => arg.value.?port ?? (arg.value.protocol == 'Http' ? 80 : 443))
      ),
      uniquePort => {
        name: '${uniquePort}'
        properties: {
          port: uniquePort
        }
      }
    )

    httpListeners: map(items(config.frontendListener), listener => {
      name: format(varNamingRef.httpListener, listener.key)
      properties: {
        protocol: listener.value.protocol
        hostName: listener.value.?hostName
        hostNames: listener.value.?hostNames

        // Reference the public IP configuration if it is provided.
        // TODO: possibility to use private ip instead of public ip.
        frontendIPConfiguration: {
          id: resourceId(
            'Microsoft.Network/applicationGateways/frontendIPConfigurations',
            varNamingRef.applicationGateway,
            varNamingRef.ipConfig.public
          )
        }
        frontendPort: {
          id: resourceId(
            'Microsoft.Network/applicationGateways/frontendPorts',
            varNamingRef.applicationGateway,
            '${listener.value.?port ?? (listener.value.protocol == 'Http' ? 80 : 443) }' // Needs to be a string, but port is an int.
          )
        }
        sslCertificate: listener.value.protocol == 'Http'
          ? null
          : {
              id: resourceId(
                'Microsoft.Network/applicationGateways/sslCertificates',
                varNamingRef.applicationGateway,
                format(varNamingRef.certificate, listener.value.?SSLCertificate)
              )
            }
        //customErrorConfigurations: [
        //  {
        //    customErrorPageUrl: 'string'
        //    statusCode: 'string'
        //  }
        //]
        //firewallPolicy: {
        //  id: 'string'
        //}
        //requireServerNameIndication: bool
        //sslProfile: {
        //  id: 'string'
        //}
      }
    })

    ////////////////////////////////////////////////
    ////////////////////////////////////////////////
    /*

    
      Request route rules and components. Connects frontend, backend and all following routing options.
      - redirect settings     - temporarly or permanently redirect to another backend
      - url path maps         - different backend pools and settings per path
      - rewriteRuleSets       - rewrite request and response headers

    */
    requestRoutingRules: map(items(config.frontendListener), listener => {
      name: format(varNamingRef.routingRule, listener.key)
      properties: {
        ruleType: !empty(listener.value.?pathRouting) ? 'PathBasedRouting' : 'Basic'
        priority: indexOf(map(items(config.frontendListener), listener => listener.key), listener.key) + 1
        httpListener: {
          id: resourceId(
            'Microsoft.Network/applicationGateways/httpListeners',
            varNamingRef.applicationGateway,
            format(varNamingRef.httpListener, listener.key)
          )
        }
        rewriteRuleSet: empty(listener.value.?rewriteRuleSet)
          ? null
          : {
              id: resourceId(
                'Microsoft.Network/applicationGateways/rewriteRuleSets',
                varNamingRef.applicationGateway,
                format(varNamingRef.rewriteRule, listener.value.?rewriteRuleSet)
              )
            }
        urlPathMap: empty(listener.value.?pathRouting)
          ? null
          : {
              id: resourceId(
                'Microsoft.Network/applicationGateways/urlPathMaps',
                varNamingRef.applicationGateway,
                format(varNamingRef.urlPathMap, listener.key)
              )
            }
        /*
            Backend Address Pool and Backend Http Settings are only supported in a Basic routing rule.
        */
        redirectConfiguration: empty(listener.value.?redirect) || !empty(listener.value.?pathRouting)
          ? null
          : {
              id: resourceId(
                'Microsoft.Network/applicationGateways/redirectConfigurations',
                varNamingRef.applicationGateway,
                format(varNamingRef.redirect, listener.key)
              )
            }
        backendAddressPool: !empty(listener.value.?pathRouting) || !empty(listener.value.?redirect)
          ? null
          : {
              id: resourceId(
                'Microsoft.Network/applicationGateways/backendAddressPools',
                varNamingRef.applicationGateway,
                format(varNamingRef.backendPool, listener.value.backendPool)
              )
            }
        backendHttpSettings: !empty(listener.value.?pathRouting) || !empty(listener.value.?redirect)
          ? null
          : {
              id: resourceId(
                'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                varNamingRef.applicationGateway,
                format(varNamingRef.backendSettings, listener.value.backendPool)
              )
            }
      }
    })

    redirectConfigurations: map(
      // Get all redirect configurations from the frontend listeners.
      // This also includes the redirect configurations from the path routing rules.
      filter(
        flatten(map(
          items(config.frontendListener),
          listener =>
            concat(
              [
                {
                  key: listener.key
                  value: listener.value.?redirect
                }
              ],
              map(items(listener.value.?pathRouting ?? {}), site => {
                key: replace('${listener.key}-${site.key}', '/', '-')
                value: site.value.?redirect
              })
            )
        )),
        item => !empty(item.value)
      ),

      redirect => {
        name: format(varNamingRef.redirect, redirect.key)
        properties: {
          redirectType: redirect.value.?type
          targetUrl: redirect.value.?externalSite
          includePath: redirect.value.?includePath ?? varDefaultSettings.listener.redirect.includePath
          includeQueryString: redirect.value.?includeQueryString ?? varDefaultSettings.listener.redirect.includeQueryString

          targetListener: empty(redirect.value.?frontendListener)
            ? null
            : {
                id: resourceId(
                  'Microsoft.Network/applicationGateways/httpListeners',
                  varNamingRef.applicationGateway,
                  format(varNamingRef.httpListener, redirect.value.?frontendListener)
                )
              }
        }
      }
    )
    urlPathMaps: map(
      filter(items(config.frontendListener), listener => !empty(listener.value.?pathRouting)),
      listener => {
        name: format(varNamingRef.urlPathMap, listener.key)
        properties: {
          defaultRewriteRuleSet: empty(listener.value.?rewriteRuleSet)
            ? null
            : {
                id: resourceId(
                  'Microsoft.Network/applicationGateways/rewriteRuleSets',
                  varNamingRef.applicationGateway,
                  format(varNamingRef.rewriteRule, listener.value.?rewriteRuleSet)
                )
              }
          defaultRedirectConfiguration: empty(listener.value.?redirect)
            ? null
            : {
                id: resourceId(
                  'Microsoft.Network/applicationGateways/redirectConfigurations',
                  varNamingRef.applicationGateway,
                  format(varNamingRef.redirect, listener.key)
                )
              }
          defaultBackendAddressPool: !empty(listener.value.?redirect)
            ? null
            : {
                id: resourceId(
                  'Microsoft.Network/applicationGateways/backendAddressPools',
                  varNamingRef.applicationGateway,
                  format(varNamingRef.backendPool, listener.value.backendPool)
                )
              }
          defaultBackendHttpSettings: !empty(listener.value.?redirect)
            ? null
            : {
                id: resourceId(
                  'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                  varNamingRef.applicationGateway,
                  format(varNamingRef.backendSettings, listener.value.backendPool)
                )
              }
          pathRules: map(items(listener.value.?pathRouting ?? {}), site => {
            name: site.value.backendPool
            properties: {
              paths: concat([site.key], site.value.?addtionalPaths ?? [])
              rewriteRuleSet: empty(site.value.?rewriteRuleSet)
                ? null
                : {
                    id: resourceId(
                      'Microsoft.Network/applicationGateways/rewriteRuleSets',
                      varNamingRef.applicationGateway,
                      format(varNamingRef.rewriteRule, site.value.rewriteRuleSet)
                    )
                  }
              redirectConfiguration: empty(site.value.?redirect)
                ? null
                : {
                    id: resourceId(
                      'Microsoft.Network/applicationGateways/redirectConfigurations',
                      varNamingRef.applicationGateway,
                      format(varNamingRef.redirect, replace('${listener.key}-${site.key}', '/', '-'))
                    )
                  }
              backendAddressPool: !empty(site.value.?redirect)
                ? null
                : {
                    id: resourceId(
                      'Microsoft.Network/applicationGateways/backendAddressPools',
                      varNamingRef.applicationGateway,
                      format(varNamingRef.backendPool, site.value.backendPool)
                    )
                  }
              backendHttpSettings: !empty(site.value.?redirect)
                ? null
                : {
                    id: resourceId(
                      'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                      varNamingRef.applicationGateway,
                      format(varNamingRef.backendSettings, site.value.backendPool)
                    )
                  }
            }
          })
        }
      }
    )

    rewriteRuleSets: map(items(config.?rewriteRuleSet ?? {}), ruleSet => {
      name: format(varNamingRef.rewriteRule, ruleSet.key)
      properties: {
        rewriteRules: map(ruleSet.value, rule => {
          name: rule.name
          ruleSequence: rule.?priority ?? indexOf(map(ruleSet.value, arg => arg.name), rule.name) + 1
          conditions: map(items(rule.?conditions ?? {}), condition => {
            variable: condition.key
            pattern: startsWith(condition.value, '!') ? substring(condition.value, 1) : condition.value
            ignoreCase: varDefaultSettings.rewriteRule.condition.ignoreCase
            negate: startsWith(condition.value, '!') ?? varDefaultSettings.rewriteRule.condition.negate
          })
          actionSet: {
            requestHeaderConfigurations: map(items(rule.?rewriteRequestHeaders ?? {}), action => {
              headerName: action.key
              headerValue: action.value
              //headerValueMatcher: {
              //  ignoreCase: action.value.?ignoreCase ?? varDefaultSettings.rewriteRule.requestHeader.ignoreCase
              //  negate: action.value.?negate ?? varDefaultSettings.rewriteRule.requestHeader.negate
              //  pattern: action.value.?pattern ?? varDefaultSettings.rewriteRule.requestHeader.pattern
              //}
            })
            responseHeaderConfigurations: map(items(rule.?rewriteResponseHeaders ?? {}), action => {
              headerName: action.key
              headerValue: action.value
              //headerValueMatcher: {
              //  ignoreCase: action.value.?ignoreCase ?? varDefaultSettings.rewriteRule.requestHeader.ignoreCase
              //  negate: action.value.?negate ?? varDefaultSettings.rewriteRule.requestHeader.negate
              //  pattern: action.value.?pattern ?? varDefaultSettings.rewriteRule.requestHeader.pattern
              //}
            })
            urlConfiguration: empty(rule.?urlConfiguration)
              ? null
              : {
                  modifiedPath: rule.urlConfiguration.?modifiedPath
                  modifiedQueryString: rule.urlConfiguration.?modifiedQueryString
                  reroute: rule.urlConfiguration.?reroute
                }
          }
        })
      }
    })
  }
}

output type string = resAppGateway.type
output id string = resAppGateway.id
output name string = resAppGateway.name

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
  scope: resAppGateway
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
    scope: resAppGateway
    name: assignment.name
    properties: {
      principalId: assignment.principalId
      roleDefinitionId: resRoleDefinition[assignment.roleIndex].id
    }
  }
]

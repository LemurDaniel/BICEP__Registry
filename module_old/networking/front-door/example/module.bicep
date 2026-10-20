import { schema } from '../../../governance/naming-schema/module.bicep'

param location string = resourceGroup().location
param environment string = 'dev'

var varDeploymentBaseName = substring(uniqueString(az.resourceGroup().name), 0, 8)

resource resStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: uniqueString('${varDeploymentBaseName}-st')
  location: 'westeurope'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

module modKeyVault '../../../security/key-vault/module.bicep' = {
  name: '${varDeploymentBaseName}-kv'
  params: {
    location: location
    schema: schema.indexBased
    naming: {
      name: uniqueString('moduleskeyvault')
      environment: environment
      projectName: 'modregistry'
    }
    config: {
      sku: 'standard'
    }
  }
}

module modIdentity '../../../security/identity/module.bicep' = {
  name: '${varDeploymentBaseName}-id'
  params: {
    location: location
    schema: schema.indexBased
    naming: {
      name: uniqueString('moduleskeyvault')
      environment: environment
      projectName: 'modregistry'
    }
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

module modFrontDoor '../module.bicep' = {
  name: '${varDeploymentBaseName}-fd'
  params: {
    location: 'global'
    schema: schema.indexBased
    naming: {
      name: uniqueString('moduleskeyvault')
      environment: environment
      projectName: 'modregistry'
    }

    config: {
      identity: {
        type: 'UserAssigned'
        userAssignedIdentities: [
          modIdentity.outputs.id
        ]
      }

      // customerCertificates: {
      //   keyVaultId: modKeyVault.outputs.id
      //   certificates: {
      //     'custom.test': {
      //       secretName: 'custom-cert'
      //     }
      //   }
      // }

      endpoints: {
        search: {
          '/*': {
            name: 'default'
            originGroup: 'search'
            ruleSet: 'headers'
          }
          '/test/*': {
            name: 'test'
            originGroup: 'search'
          }
        }
      }
      originGroups: {
        search: {
          healthProbe: {
            enabled: false
          }
          origins: {
            bing: {
              hostName: 'bing.com'
            }
          }
        }
      }

      ruleSets: {
        headers: {
          rules: [
            {
              name: 'rewriteCustomHeaders'
              ModifyRequestHeaders: {
                'some-custom-header': {
                  headerAction: 'Append'
                  headerValue: 'Bla Bla'
                }
              }
            }
            {
              name: 'cacheControl'
              CacheExpiration: {
                behavior: 'Override'
                duration: '00:05:00'
              }
            }
            {
              name: 'cacheKey'
              CacheKeyQueryString: {
                behavior: 'Include'
                queryParameters: ['bla']
              }
            }
          ]
        }
      }
    }

    diagnosticSettings: {
      logs: ['AllLogs']
      storageAccountId: '/subscriptions/6ad43a20-9532-41c0-ad61-885a26bef90f/resourceGroups/rg-servicebus-test-001/providers/Microsoft.Storage/storageAccounts/rgservicebustest001a1d9'
    }

    roleAssignments: [
      {
        principalId: deployer().objectId
        roleDefinitions: [
          'Reader'
          'Contributor'
        ]
      }
    ]
  }
}

import { defaultSchema } from '../../../governance/naming-schema/module.bicep'
import { name } from '../../../governance/naming/module.bicep'

param location string = resourceGroup().location
param environment string = 'dev'

var varDeploymentBaseName = substring(uniqueString(az.resourceGroup().name), 0, 8)

resource resPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: name('Microsoft.Network/publicIPAddresses', defaultSchema, {
    location: location
    environment: environment
    name: 'moduletest'
  })
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

module modVnet '../../virtual-network/module.bicep' = {
  name: '${varDeploymentBaseName}-vnet'
  params: {
    location: location
    schema: defaultSchema
    naming: {
      environment: environment
      name: 'moduletest'
    }
    config: {
      addressSpace: '10.0.0.0/24'
      subnet: {
        appgateway: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: [
            'Microsoft.KeyVault'
          ]
        }
      }
    }
  }
}

module modKeyVault '../../../security/key-vault/module.bicep' = {
  name: '${varDeploymentBaseName}-kv'
  params: {
    location: location
    schema: defaultSchema
    naming: {
      environment: environment
      name: 'moduletest'
    }
    config: {
      sku: 'standard'
      enableRbacAuthorization: true
      softDeleteRetentionInDays: 90

      networkAccess: {
        defaultAction: 'Deny'
        subnetRules: [
          modVnet.outputs.subnet.appgateway.id
        ]
      }
    }
  }
}

module modIdentity '../../../security/identity/module.bicep' = {
  name: '${varDeploymentBaseName}-id'
  params: {
    location: location
    schema: defaultSchema
    naming: {
      environment: environment
      name: 'moduletest'
    }
    roleAssignments: [
      {
        resourceId: modKeyVault.outputs.id
        roleDefinitions: [
          'Key Vault Secrets User'
        ]
      }
    ]
  }
}

module modAppGateway '../module.bicep' = {
  name: '${varDeploymentBaseName}-gateway'
  params: {
    location: location
    schema: defaultSchema
    naming: {
      environment: environment
      name: 'moduletest'
    }
    config: {
      sku: {
        name: 'Standard_v2'
        tier: 'Standard_v2'
        capacity: 1
      }
      network: {
        publicIp: {
          id: resPublicIp.id
        }
        subnetId: modVnet.outputs.subnet.appgateway.id
      }

      keyVault: {
        id: modKeyVault.outputs.id
        identityId: modIdentity.outputs.id
      }

      backendPool: {
        app01Dev: {
          protocol: 'Http&Https'
          fqdn: 'bing.com'
        }
        app02Dev: {
          protocol: 'Http'
          fqdn: 'google.com'
        }
      }

      frontendListener: {
        app01: {
          protocol: 'Http'
          backendPool: 'app01Dev-https'
          rewriteRuleSet: 'rewriteRuleSet01'

          //redirect: {
          //  type: 'Temporary'
          //  externalSite: 'https://www.bing.com'
          //}

          pathRouting: {
            '/google': {
              backendPool: 'app02Dev'

              redirect: {
                type: 'Temporary'
                externalSite: 'https://www.google.com'
              }
            }
            '/bing': {
              backendPool: 'app01Dev-http'
            }
          }
        }
      }

      rewriteRuleSet: {
        rewriteRuleSet01: [
          {
            name: 'rule01'
            condition: {
              Accept: '!text/html'
            }
            rewriteRequestHeaders: {
              Accept: 'text/plain'
            }
            rewriteResponseHeaders: {
              'Content-Type': 'text/plain'
            }
          }
        ]
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

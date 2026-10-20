targetScope = 'subscription'

import { schema } from '../../../../governance/naming-schema/module.bicep'

param exampleIdentifier string = 'module-registry.solutions.subscription.application-gateway'
//
//

param location string = deployment().location
param environment string
param config object

module modDeployFronDoor '../module.bicep' = {
  name: '${substring(uniqueString(exampleIdentifier), 0, 8)}-sub'
  params: {
    location: location
    schema: schema.indexBased
    naming: {
      name: uniqueString(exampleIdentifier)
      environment: environment
      projectName: 'modregistry'
    }
    config: config
  }
}

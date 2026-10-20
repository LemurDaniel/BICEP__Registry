import { defaultSchema } from '../../../governance/naming-schema/module.bicep'

var varDeploymentBaseName = substring(uniqueString(az.resourceGroup().name), 0, 8)

param location string = resourceGroup().location
param environment string

module modStorageAccount '../module.bicep' = {
  name: '${varDeploymentBaseName}-st'
  params: {
    location: location

    namingSchema: defaultSchema
    naming: {
      environment: environment
      name: uniqueString(varDeploymentBaseName)
    }

    allowBlobPublicAccess: true

    fileshare: {
      fileshare1: {
        name: 'fileshare1'
        quota: 10
      }
      fileshare2: {
        name: 'fileshare2'
        quota: 20
      }
      fileshare3: {
        name: 'fileshare3'
        quota: 30
        accessTier: 'Hot'
      }
    }

    container: {
      container1: 'Container'
      container2: 'Blob'
      container3: 'Private'
    }

    queue: [
      'queue1'
      'queue2'
    ]

    table: [
      'table1'
      'table2'
    ]

    diagnosticSettings: {}
  }
}

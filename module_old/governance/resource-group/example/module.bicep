targetScope = 'subscription'

param location string = deployment().location
param environment string

var varDefaultSettings = {
  deploymentBaseName: '${substring(uniqueString(az.subscription().displayName), 0, 8)}-resourceGroup'
}

module modResourceGroup '../module.bicep' = {
  name: '${varDefaultSettings.deploymentBaseName}-rg'
  params: {
    location: location
    naming: {
      name: uniqueString(varDefaultSettings.deploymentBaseName)
      environment: environment
    }
  }
}

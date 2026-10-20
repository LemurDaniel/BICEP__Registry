

## !!! DON'T USE THIS MODULE !!!

Currently it is not possible to output a scope from a module, that can be passed to following modules. This makes this module unusable in conjuction with other modules, since a wrapper module needs always be created to deal with the resource group scope.

## !!! Use nameResourceGroup(() instead !!!

The naming module exports a special shortcut function for creating resource group names. This way one can still benefit from an easy interface with the naming module, while being able to use resource group scope references.

```bicep
resource resGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  // Special function to quickly create a name from the naming schema
  name: nameResourceGroup((naming, location, schema)
  location: location
  tags: tags
}

module modFrontDoor '../resource-group/module.bicep' = {
  name: '${varSettings.deploymentBaseName}-wrapper-rg'
  // Using reference to the resourceGroup for deploying on this scope.
  // This isn't possible when using the module, so adviced to resort to the function instead!
  scope: resGroup
  params: {
    tags: tags
    overwrite: overwrite
    schema: schema
    naming: naming
    location: location
    config: config
  }
}
```

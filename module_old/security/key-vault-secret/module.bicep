// param subDeploymentPrefix string = null

////////////////////////////////////////////////
//// Location and Tags

// param location string = resourceGroup().location
// param tags {
//   *: string
// } = {}

////////////////////////////////////////////////
//// Module Parameter

param keyVaultName string

@secure()
param secrets {
  *: {
    value: string
    contentType: string?

    @description('''
      If set to true, the secret will be overwritten if it already exists.
      If set to false, the secret will only be set once!
      Defaults to true.
    ''')
    overwrite: bool?
  }
}

////////////////////////////////////////////////
//// Deploy key vault

resource resKeyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

var varOverwriteSecrets = filter(items(secrets), s => s.value.?overwrite ?? true)
resource resourceKvSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = [
  for secret in varOverwriteSecrets: {
    parent: resKeyVault
    name: secret.key
    properties: {
      value: secret.value.value
      contentType: secret.value.?contentType
    }
  }
]

var varStaticSecrets = filter(items(secrets), s => !(s.value.?overwrite ?? true))

@onlyIfNotExists()
resource resourceKvStaticSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = [
  for secret in varStaticSecrets: {
    parent: resKeyVault
    name: secret.key
    properties: {
      value: secret.value.value
      contentType: secret.value.?contentType
    }
  }
]

/*

  #################################################
  #### Module outputs

*/

output type string = resKeyVault.type
output id string = resKeyVault.id
output name string = resKeyVault.name

output url string = resKeyVault.properties.vaultUri

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

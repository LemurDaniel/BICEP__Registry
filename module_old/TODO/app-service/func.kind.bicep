type typeKind =
  | 'api'
  | 'app'
  | 'app,container,windows'
  | 'app,linux'
  | 'app,linux,container'
  | 'functionapp'
  | 'functionapp,linux'
  | 'functionapp,linux,container'
  | 'functionapp,linux,container,azurecontainerapps'
  | 'functionapp,workflowapp'
  | 'functionapp,workflowapp,linux'
  | 'linux,api'

@export()
func getKind(runtime object, os string, kind string) typeKind =>
  {
    'Docker-Linux-App': 'app,linux,container'
    'Python-Linux-App': 'app,linux'
  }[?'${objectKeys(runtime)[0]}-${os == 'linux' ? 'Linux' : 'Windows'}-${kind}'] ?? fail('This module currently doesnt support the combination of ${objectKeys(runtime)[0]}-${os}-${kind}.')

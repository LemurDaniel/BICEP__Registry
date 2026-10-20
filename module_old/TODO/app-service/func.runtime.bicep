@export()
type typeRuntime = {
  // name: 'Docker' | 'dotnet' | 'dotnetcore' | 'dotnet-isolated' | 'node' | 'python' | 'java' | 'powershell' | 'custom'
  // version: string

  Docker: {
    identityClientId: string?
    registryUrl: string
    imageName: string
  }?

  Python: {
    version: string
    commandLine: string

    enableOryxBuild: bool?
    scmDoBuildDuringDeployment: bool?
  }?
}

@export()
@description('''
This selects the first runtime configuration found.
Then it returns the appropriate default site configuration.
''')
func getRuntimeConfig(runtime typeRuntime) object =>
  siteconfig(map(items(runtime), arg => union(arg.value, { type: arg.key }))[?0] ?? fail('Runtime type is required. Please specify a runtime type.'))

func siteconfig(runtime object) object =>
  {
    Docker: runtime.type == 'Docker' ? Docker(runtime) : null
    Python: runtime.type == 'Python' ? Python(runtime) : null
  }[?runtime.type] ?? fail('Runtime ${runtime.type} is currently not supported.')

func Docker(runtime object) object => {
  siteConfig: {
    acrUseManagedIdentityCreds: true
    acrUserManagedIdentityId: runtime.identityClientId
    linuxFxVersion: 'DOCKER|${runtime.registryUrl}/${runtime.imageName}'
  }
  appSettings: {}
}

func Python(runtime object) object => {
  siteConfig: {
    pythonVersion: runtime.version
    linuxFxVersion: 'PYTHON|${runtime.commandLine}'
  }
  appSettings: {
    SCM_DO_BUILD_DURING_DEPLOYMENT: (runtime.?scmDoBuildDuringDeployment ?? true) ? 'True' : 'False'
    ENABLE_ORYX_BUILD: (runtime.?enableOryxBuild ?? false) ? 'True' : 'False'
  }
}

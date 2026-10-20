using './module.bicep'

param environment = 'dev'

param config = {
  keyVault: {
    ipRules: []
  }

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
      name: 'customheaders'
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
      ]
    }
  }
}

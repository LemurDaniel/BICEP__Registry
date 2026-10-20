using './module.bicep'

param environment = 'dev'

param config = {
  keyVault: {
    ipRules: []
  }

  backendPool: {
    google: {
      protocol: 'Https'
      fqdn: 'google.com'
    }
    microsoft: {
      protocol: 'Https'
      fqdn: 'microsoft.com'
    }
  }

  frontendListener: {
    app01: {
      protocol: 'Http'
      backendPool: 'google'
      rewriteRuleSet: 'headerRewrite'

      redirect: {
        type: 'Temporary'
        externalSite: 'https://www.bing.com'
      }

      pathRouting: {
        '/microsoft': {
          backendPool: 'microsoft'

          redirect: {
            type: 'Temporary'
            externalSite: 'https://www.google.com'
          }
        }
      }
    }
  }

  rewriteRuleSet: {
    headerRewrite: [
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

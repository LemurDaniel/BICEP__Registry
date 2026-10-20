@export()
type configuration = {
  @description('The key vault for reading certificates and secrets.')
  keyVault: {
    id: string
    identityId: string
  }?

  @description('The network configuration for the application gateway.')
  network: {
    @description('Use a custom deployed public ip for this module.')
    publicIp: {
      id: string?
    }
    privateIp: string?
    subnetId: string
  }

  @description('The SKU configuration for the application gateway.')
  sku: {
    name: 'Standard_v2' | 'WAF_v2'
    tier: 'Standard_v2' | 'WAF_v2'
    capacity: int?
  }?

  @description('At least one backend pool is required. They are referenced by the frontend listeners via the key')
  backendPool: typeBackendPool

  frontendListener: typeFrontendListener

  rewriteRuleSet: typeRewriteRuleset
}

@export()
type typeRewriteRuleset = {
  *: {
    name: string
    @description('The priority. Will default to the index of the rule in the array.')
    priority: int?

    urlConfiguration: {
      modifyPath: string
      modifyQueryString: string
      reroute: bool
    }?

    @description('Prefix the pattern with a ! to negate the pattern.')
    condition: {
      *: string?

      // These are some common headers. 
      // This provides nice autocompletion when working with bicep-extensions.
      'Access-Control-Allow-Origin': string?
      'Access-Control-Allow-Credentials': string?
      'Access-Control-Expose-Headers': string?
      'Access-Control-Max-Age': string?
      'Access-Control-Allow-Methods': string?
      'Access-Control-Allow-Headers': string?
      'Accept-Patch': string?
      'Accept-Ranges': string?
      'Age': string?
      'Allow': string?
      'Alt-Svc': string?
      'Cache-Control': string?
      'content-Disposition': string?
      'Content-Encoding': string?
      'Content-Language': string?
      'Content-Length': string?
      'Content-Location': string?
      'Content-MD5': string?
      'Content-Range': string?
      'Content-Type': string?
      'Date': string?
      'Delta-Base': string?
      'ETag': string?
      'Expires': string?
      'IM': string?
      'Last-Modified': string?
      'Link': string?
      'Location': string?
      'P3P': string?
      'Pragma': string?
      'Proxy-Authenticate': string?
      'Public-Key-Pins': string?
      'Retry-After': string?
      'Server': string?
      'Set-Cookie': string?
      'Strict-Transport-Security': string?
      'Trailer': string?
      'Transfer-Encoding': string?
      'Tk': string?
      'Vary': string?
      'Via': string?
      'Warning': string?
      'WWW-Authenticate': string?
      'X-Frame-Options': string?
      'Content-Security-Policy': string?
      'X-Content-Security-Policy': string?
      'X-WebKit-CSP': string?
      'X-powered-by': string?
      'X-XSS-Protection': string?
      'Accept': string?
      'Accept-Language': string?
      'Accept-Encoding': string?
      'Accept-Charset': string?
      'Accept-Datetime': string?
      'Access-Control-Request-Method': string?
      'Access-Control-Request-Headers': string?
      'Authorization': string?
      'Expect': string?
      'Forwarded': string?
      'From': string?
      'Host': string?
      'If-Match': string?
      'If-Modified-Since': string?
      'If-None-Match': string?
      'If-Range': string?
      'If-Unmodified-Since': string?
      'Max-Forwards': string?
      'Origin': string?
      'Proxy-Authorization': string?
      'Range': string?
      'Referer': string?
      'TE': string?
      'User-Agent': string?
      'Upgrade': string?
      'X-Requested-With': string?
      'DNT': string?
      'X-Forwarded-For': string?
      'X-Forwarded-Host': string?
      'X-Forwarded-Proto': string?
      'Front-End-Https': string?
      'X-Http-Method-Override': string?
    }
    rewriteRequestHeaders: {
      *: string
      // These are some common headers. 
      // This provides nice autocompletion when working with bicep-extensions.
      'Accept': string?
      'Accept-Language': string?
      'Accept-Encoding': string?
      'Accept-Charset': string?
      'Accept-Datetime': string?
      'Access-Control-Request-Method': string?
      'Access-Control-Request-Headers': string?
      'Authorization': string?
      'Cache-Control': string?
      'Content-Type': string?
      'Content-Length': string?
      'Content-MD5': string?
      'Date': string?
      'Expect': string?
      'Forwarded': string?
      'From': string?
      'Host': string?
      'If-Match': string?
      'If-Modified-Since': string?
      'If-None-Match': string?
      'If-Range': string?
      'If-Unmodified-Since': string?
      'Max-Forwards': string?
      'Origin': string?
      'Pragma': string?
      'Proxy-Authorization': string?
      'Range': string?
      'Referer': string?
      'TE': string?
      'User-Agent': string?
      'Upgrade': string?
      'Via': string?
      'Warning': string?
      'X-Requested-With': string?
      'DNT': string?
      'X-Forwarded-For': string?
      'X-Forwarded-Host': string?
      'X-Forwarded-Proto': string?
      'Front-End-Https': string?
      'X-Http-Method-Override': string?
    }?
    rewriteResponseHeaders: {
      *: string
      // These are some common headers. 
      // This provides nice autocompletion when working with bicep-extensions.
      'Access-Control-Allow-Origin': string?
      'Access-Control-Allow-Credentials': string?
      'Access-Control-Expose-Headers': string?
      'Access-Control-Max-Age': string?
      'Access-Control-Allow-Methods': string?
      'Access-Control-Allow-Headers': string?
      'Accept-Patch': string?
      'Accept-Ranges': string?
      'Age': string?
      'Allow': string?
      'Alt-Svc': string?
      'Cache-Control': string?
      'content-Disposition': string?
      'Content-Encoding': string?
      'Content-Language': string?
      'Content-Length': string?
      'Content-Location': string?
      'Content-MD5': string?
      'Content-Range': string?
      'Content-Type': string?
      'Date': string?
      'Delta-Base': string?
      'ETag': string?
      'Expires': string?
      'IM': string?
      'Last-Modified': string?
      'Link': string?
      'Location': string?
      'P3P': string?
      'Pragma': string?
      'Proxy-Authenticate': string?
      'Public-Key-Pins': string?
      'Retry-After': string?
      'Server': string?
      'Set-Cookie': string?
      'Strict-Transport-Security': string?
      'Trailer': string?
      'Transfer-Encoding': string?
      'Tk': string?
      'Vary': string?
      'Via': string?
      'Warning': string?
      'WWW-Authenticate': string?
      'X-Frame-Options': string?
      'Content-Security-Policy': string?
      'X-Content-Security-Policy': string?
      'X-WebKit-CSP': string?
      'X-powered-by': string?
      'X-XSS-Protection': string?
    }?
  }[]
}?

@export()
type typeFrontendListener = {
  *: {
    @description('The port for the frontend listener. If not provided, the port will be inferred from the protocol.')
    port: int?

    @description('The protocol for the frontend listener.')
    protocol: 'Http' | 'Https'

    @description('The host name for the frontend listener. Either define a single host name or multiple host names. If both are provided, the host names will be used.')
    hostName: string?
    hostNames: string[]?

    @description('The SSL certificate for the frontend listener. If not provided, the listener will not use SSL.')
    SSLCertificate: string?

    redirect: {
      type: 'Permanent' | 'Temporary' | 'Found' | 'SeeOther'
      frontendListener: string?
      externalSite: string?

      includePath: bool?
      includeQueryString: bool?
    }?

    @description('In case of pathRouting listener, this backend pool gets interpreted as the default backend pool.')
    backendPool: string
    pathRouting: {
      *: {
        backendPool: string
        rewriteRuleSet: string?
        addtionalPaths: string[]?

        redirect: {
          type: 'Permanent' | 'Temporary' | 'Found' | 'SeeOther'
          frontendListener: string?
          externalSite: string?

          includePath: bool?
          includeQueryString: bool?
        }?
      }
    }?

    rewriteRuleSet: string?
  }
}

@export()
type typeBackendPool = {
  *: {
    @description('Define a single fqdn or multiple fqdns. If both are provided, they will be combined.')
    fqdn: string?
    fqdns: string[]?

    @description('Define a single ip or multiple ips. If both are provided, they will be combined.')
    ip: string?
    ips: string[]?

    @description('''
    The port for the backend pool. If not provided, the port will be inferred from the protocol.
    When using Http&Https the pools need to be addressed as poolname-http or poolname-https
    ''')
    port: int?
    protocol: 'Http' | 'Https' | 'Http&Https'

    override: {
      @description('Override the path for the backend pool.')
      path: string?
      @description('Override the host name for the backend pool. (This is useful for sending the correct hostname to the backend for SSL with HTTPS). If not provided, the host name will be inferred from the fqdn or ip.')
      hostName: string?
    }?

    affinityCookieName: string?
    drainTimeoutInSec: int?
    requestTimeout: int?

    @description('The health probe configuration for the backend pool. If not provided, the health probe will be enabled by default.')
    healthPrope: {
      enabled: bool?

      @description('Choose a different protocol for the health probe. If not provided, the protocol will be inferred from the backend pool.')
      protocol: 'Http' | 'Https'?

      @description('The path for the health probe. If not provided, the path will be inferred from the protocol.')
      port: int?

      @description('The path for the health probe. Default is "/".')
      path: string?

      @description('The host for the health probe. If not provided, the host will be inferred from the backend pool.')
      host: string?

      interval: int?
      timeout: int?
      unhealthyThreshold: int?
      minHealthyBackend: int?

      @description('The condition for the health probe. If not provided, defaults to empty and 200 as allowed status code.')
      condition: {
        body: string?
        statusCodes: string[]?
      }?
    }?
  }
}

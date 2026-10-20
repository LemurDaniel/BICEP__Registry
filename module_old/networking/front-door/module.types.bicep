@export()
type configuration = {
  sku:
    | 'Standard_AzureFrontDoor'
    | 'Standard_Microsoft'
    | 'Custom_Verizon'
    | 'Premium_AzureFrontDoor'
    | 'Premium_Verizon'
    | 'StandardPlus_955BandWidth_ChinaCdn'
    | 'StandardPlus_AvgBandWidth_ChinaCdn'
    | 'StandardPlus_ChinaCdn'
    | 'Standard_955BandWidth_ChinaCdn'
    | 'Standard_Akamai'
    | 'Standard_AvgBandWidth_ChinaCdn'
    | 'Standard_ChinaCdn'
    | 'Standard_Verizon'?

  identity: {
    type: 'SystemAssigned' | 'UserAssigned' | 'SystemAssigned,UserAssigned'?
    userAssignedIdentities: string[]?
  }?

  customerCertificates: {
    keyVaultId: string
    certificates: {
      *: {
        secretName: string
        alternateNames: string[]?
        @description('The version of the secret to use. If not provided, the latest version will be used.')
        secretVersion: string?
      }
    }
  }?

  endpoints: {
    *: {
      @description('Define naming parameters for this resource. Any provided naming parameters will be used with higher priorty of the inherited naming parameter.')
      naming: {
        index: int?
        name: string?
        overwrite: string?
        *: string?
      }?

      '/*': endpointRoute?
      *: endpointRoute?
    }
  }

  originGroups: {
    *: originGroup
  }

  ruleSets: {
    *: ruleSet
  }?
}

@export()
type endpointRoute = {
  @description('The name of the route. No name generator is applied.')
  name: string?

  @description('The key of the origin group to reference.')
  originGroup: string
  @description('The key of the rule set to reference.')
  ruleSet: string?
  ruleSets: string[]?

  disable: bool?
  originPath: string?
  enableDefaultDomain: bool?
  additonalPatterns: string[]?
  httpsRedirect: bool?
  forwardingProtocol: 'HttpOnly' | 'HttpsOnly' | 'MatchRequest'?
  supportedProtocols: 'HttpOnly' | 'HttpsOnly' | 'Http;Https'?

  caching: {
    enabled: bool?
    behavior: 'IgnoreQueryStrign' | 'IgnoreSpecifiedQueryStrings' | 'IncludeSpecifiedQueryStrings' | 'UseQueryString'?
    queryParameters: string[]?
    compression: bool?
  }?
}

@export()
type originGroup = {
  @description('Define naming parameters for this resource. Any provided naming parameters will be used with higher priorty of the inherited naming parameter.')
  naming: {
    index: int?
    name: string?
    overwrite: string?
    *: string?
  }?

  sessionAffinity: bool?
  healthProbe: {
    enabled: bool?
    intervalInSeconds: int?
    path: string?
    protocol: 'Http' | 'Https'?
    method: 'GET' | 'HEAD' | 'NotSet'?
  }?
  loadBalancing: {
    additionalLatencyInMilliseconds: int?
    successfulSamplesRequired: int?
    sampleSize: int?
  }?
  trafficRestorationTimeToHealedOrNewEndpointsInMinutes: int?

  origins: {
    *: {
      @description('The host name of the origin.')
      hostName: string

      httpPort: int?
      httpsPort: int?

      priority: 1 | 2 | 3 | 4 | 5?

      @maxValue(1000)
      @minValue(1)
      weight: int?

      @description('Parameter to override the host header sent to the origin.')
      hostHeader: string?
    }
  }
}

@export()
type ruleSet = {
  @description('Define naming parameters for this resource. Any provided naming parameters will be used with higher priorty of the inherited naming parameter.')
  naming: {
    index: int?
    name: string?
    overwrite: string?
    *: string?
  }?

  matchProcessingBehavior: 'Continue' | 'Stop'?
  rules: {
    @description('The name of the rule. No name generator is applied.')
    name: string

    'ModifyRequestHeaders': {
      *: {
        headerValue: string
        headerAction: 'Append' | 'Delete' | 'Overwrite'
      }
    }?

    'ModifyResponseHeaders': {
      *: {
        headerValue: string
        headerAction: 'Append' | 'Delete' | 'Overwrite'
      }
    }?

    'OriginGroupOverride': {
      originGroup: {
        id: string
      }
    }?

    //'RouteConfigurationOverride'

    //'UrlRedirect': {
    //  customFragment: 'string'
    //  customHostname: 'string'
    //  customPath: 'string'
    //  customQueryString: 'string'
    //  destinationProtocol: 'string'
    //  redirectType: 'string'
    //}

    //'UrlRewrite': {
    //  destination: 'string'
    //  preserveUnmatchedPath: bool
    //  sourcePattern: 'string'
    //}

    // UrlSigning

    //'AfdUrlSigning': {
    //  algoritm: 'SHA256'?
    //  keyGroup: string //TODO
    //}?

    'CacheExpiration': {
      behavior: 'BypassCache' | 'Override' | 'SetIfMissing'
      @description('In format [d.]hh:mm:ss')
      duration: string
    }?

    'CacheKeyQueryString': {
      behavior: 'Include' | 'IncludeAll' | 'Exclude' | 'ExcludeAll'
      queryParameters: string[]
    }?
  }[]
}

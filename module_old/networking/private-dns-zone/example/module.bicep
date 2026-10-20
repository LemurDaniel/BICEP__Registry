// param location string = resourceGroup().location
// param environment string = 'dev'

var varDefaultSettings = {
  deploymentBaseName: '${substring(uniqueString(az.resourceGroup().name), 0, 8)}-dns'
}

module dnsZone '../module.bicep' = {
  name: varDefaultSettings.deploymentBaseName
  params: {
    services: {
      'Microsoft.Storage/storageAccounts': {
        blob: {
          a: {
            'A_10.240.4.3': {
              ipv4Address: '10.240.4.3'
              ttl: 2400
            }
          }
          aaaa: {
            AAAA_2001: {
              ipv6Address: '2001:0db8:85a3:0000:0000:8a2e:0370:7334'
              ttl: 2400
            }
          }
          cname: {
            CNAME_blob: {
              cname: 'test.bla.not'
              ttl: 2400
            }
          }
          txt: {
            TXT_blob: {
              txt: [
                'This is a TXT record for blob storage'
                'Another line of text'
                'Yet another line'
              ]
              ttl: 2400
            }
          }
        }
        file: null
        queue: null
      }
      'Microsoft.Search/searchServices': null
    }
  }
}

import { typeDnsServices } from 'type.dns.bicep'
param input typeDnsServices

param result {
  id: string
  name: string
  resourceGroup: string

  service: string
  subService: string
  privateDns: string
}[]

var varServiceOutputReference = toObject(result, arg => '${arg.service}-${arg.subService}', arg => arg)

/*
  
   This is a list of all services with a map of their deployd sub-service dns-zones

   [
    {
      service: 'Microsoft.Storage/storageAccounts'
      subService: {
        'blob': {
          id: string
          name: string
        }
        'file': {
          id: string
          name: string
        }
      }
    }
   ]

*/
var varRefBySubService = [
  for (service, index) in items(input): {
    service: service.key
    subService: toObject(
      items(service.?value ?? { default: {} }),
      subService => subService.key,
      subService => varServiceOutputReference['${service.key}-${subService.key}']
    )
  }
]

////////////////////////////////////////////////
////////////////////////////////////////////////
//// Output - refByService

output refByService {
  *: {
    *: {
      id: string
      name: string
      resourceGroup: string

      service: string
      subService: string
      privateDns: string
    }
  }
} = toObject(varRefBySubService, arg => arg.service, arg => arg.subService)

////////////////////////////////////////////////
////////////////////////////////////////////////
//// Output - refByDomain

output refByDomain {
  *: {
    id: string
    name: string
    resourceGroup: string

    service: string
    subService: string
    privateDns: string
  }
} = toObject(result, arg => arg.privateDns, arg => arg)

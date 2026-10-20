import { getDefaultPrivateDns } from './variable.dns.bicep'
import { typeDnsServices } from './type.dns.bicep'

////////////////////////////////////////////////
//// Location and Tags

param subDeploymentName string = deployment().name
param location string = 'global'
param tags {
  *: string
} = {}

////////////////////////////////////////////////
//// Parameters

param services typeDnsServices

import { virtualNetworkLinkType } from 'br/public:avm/res/network/private-dns-zone:0.7.1'
param virtualNetworkLinks virtualNetworkLinkType[] = []

param resourceLock 'None' | 'ReadOnly' | 'CanNotDelete' = 'None'
param defaultTTL int = 3600 // Default TTL for DNS records in seconds

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
///// Private DNS Zone Resource

/*
  Folgendes erstellt eine Liste von Listen, die die private DNS Konfigurationen für die jeweiligen Services enthalten.

  Über flatten() wird diese zu einer einzigen Liste zusammengeführt.

  [
    [
      {
        serviceName: 'Microsoft.Storage/storageAccounts'
        subServiceName: 'blob'
        privateDnsName: 'privatelink.blob.${az.environment().suffixes.storage}'
      },
      { 
        serviceName: 'Microsoft.Storage/storageAccounts'
        subServiceName: 'file'
        privateDnsName: 'privatelink.file.${az.environment().suffixes.storage}'
      }
    ],
    [
      { 
        serviceName: 'Microsoft.Web/sites'
        subServiceName: 'default'
        privateDnsName: 'privatelink.azurewebsites.net'
      }
    ]
  ]
  
*/

var varServiceDnsConfigs = [
  for (service, index) in items(services): map(
    length(service.?value ?? {}) > 0 ? items(service.?value) : items({ default: {} }),
    // Searches the privates DNS name for the subService of a service.
    subService => {
      service: service.key
      subService: subService.key
      privateDns: getDefaultPrivateDns(service.key, subService.key).name
      records: {
        a: subService.?value.?a ?? {}
        aaaa: subService.?value.?aaaa ?? {}
        cname: subService.?value.?cname ?? {}
        txt: subService.?value.?txt ?? {}
      }
    }
  )
]

var varServiceDnsConfigsFlat = flatten(varServiceDnsConfigs)

module modPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.1' = [
  for (dnsConfig, index) in varServiceDnsConfigsFlat: {
    name: length(subDeploymentName) + length('XXX.avm.dns.0.7.1') > 64
      ? '${uniqueString(subDeploymentName)}.${index}.avm.dns.0.7.1'
      : '${subDeploymentName}.${index}.avm.dns.0.7.1'
    params: {
      enableTelemetry: false

      tags: tags
      location: location
      name: dnsConfig.privateDns

      virtualNetworkLinks: virtualNetworkLinks

      lock: resourceLock != 'None'
        ? {
            name: 'DO_NOT_DELETE__PRIVATE_DNS_ZONE'
            kind: resourceLock
          }
        : null

      a: map(items(dnsConfig.records.a), record => {
        name: record.key
        ttl: record.value.ttl ?? defaultTTL
        aRecords: [
          {
            ipv4Address: record.value.ipv4Address
          }
        ]
      })

      aaaa: map(items(dnsConfig.records.aaaa), record => {
        name: record.key
        ttl: record.value.ttl ?? defaultTTL
        aaaaRecords: [
          {
            ipv6Address: record.value.ipv6Address
          }
        ]
      })

      cname: map(items(dnsConfig.records.cname), record => {
        name: record.key
        ttl: record.value.ttl ?? defaultTTL
        cnameRecord: {
          cname: record.value.cname
        }
      })

      txt: map(items(dnsConfig.records.txt), record => {
        name: record.key
        ttl: record.value.ttl ?? defaultTTL
        txtRecords: [
          {
            value: record.value.txt
          }
        ]
      })
    }
  }
]

////////////////////////////////////////////////
//// Output - transform module outputs in seperate module

module modTransform 'module.transform.bicep' = {
  name: format('{0}.{1}', subDeploymentName, substring(uniqueString(join(map(items(services), s => s.key), '.')), 0, 3))
  params: {
    input: services
    result: [
      for (item, index) in varServiceDnsConfigsFlat: {
        id: modPrivateDnsZone[index].outputs.resourceId
        name: modPrivateDnsZone[index].outputs.name
        resourceGroup: modPrivateDnsZone[index].outputs.resourceGroupName

        service: item.service
        subService: item.subService
        privateDns: item.privateDns
      }
    ]
  }
}

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
} = modTransform.outputs.refByService

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
} = modTransform.outputs.refByDomain

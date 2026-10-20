

/*

  NOTE: Requires Version 0.26.x or higher
  https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions

*/

import {
  GetSegmentFromId
  AddItemToArray
  AddStringToArray
  GetCustomIndexer
} from '../module.bicep'

output segments object = GetSegmentFromId(resourceGroup().id)

output addStringToArray array = AddStringToArray(['1', '2', '3'], '4')

output customIndexer array = GetCustomIndexer(['a', 'b', 'c', 'd', 'e'])

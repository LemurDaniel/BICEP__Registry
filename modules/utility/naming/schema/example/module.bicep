

// param location string = resourceGroup().location
// param environment string = 'dev'


import { schema } from '../module.bicep'

output schemas object = schema

import { jsonTemplate } from '../module.bicep'

param parameter object = {
  environment: 'dev'
  createdBy: 'daniel'
  vmSize: 'Standard_B2s'
  projectName: 'RadonProject'
  owner: 'TeamInfra'
  dbVersion: '1.2'
  dbHost: 'db.radon.local'
  webServerIp: '10.0.0.4'
}

param testBasicJson string = loadTextContent('test.basic.json')
param testMultiParamLine string = loadTextContent('test.multiParamLine.json')
param testFallbackValues string = loadTextContent('test.fallbackValues.json')
param testCompressedJson string = loadTextContent('test.compressed.json')

output parameterizedObjectBasic object = jsonTemplate(testBasicJson, parameter)
output parameterizedMultiParamLine object = jsonTemplate(testMultiParamLine, parameter)
output parameterizedObjectCompressed object = jsonTemplate(testCompressedJson, parameter)
output parameterizedObjectFallback object = jsonTemplate(testFallbackValues, {}) // No parameter object is passed in, so it will use the fallback values from the JSON file.

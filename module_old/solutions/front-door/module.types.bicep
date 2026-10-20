import { typeNaming } from '../../governance/naming/module.bicep'
import { typeDiagnosticSettings } from '../../utility/diagnostic-utility/module.bicep'
import { originGroup, ruleSet, endpointRoute } from '../../networking/front-door/module.types.bicep'

@export()
type configuration = {
  keyVault: {
    naming: typeNaming?
    ipRules: string[]
    diagnosticSettings: typeDiagnosticSettings
  }

  identity: {
    naming: typeNaming?
  }?

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

  // NOT NECESSARY for solution module
  // identity: {
  //   type: 'SystemAssigned' | 'UserAssigned' | 'SystemAssigned,UserAssigned'?
  //   userAssignedIdentities: string[]?
  // }?

  customerCertificates: {
    // NOT NECESSARY for solution module
    // keyVaultId: string
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
      naming: typeNaming?
      '/*': endpointRoute?
      *: endpointRoute?
    }
  }

  originGroups: {
    *: originGroup
  }

  ruleSets: {
    *: ruleSet?
  }

  diagnosticSettings: typeDiagnosticSettings
}

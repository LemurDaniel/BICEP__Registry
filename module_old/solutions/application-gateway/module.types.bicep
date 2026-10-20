import { typeNaming } from '../../governance/naming/module.bicep'
import { typeDiagnosticSettings } from '../../utility/diagnostic-utility/module.bicep'
import { typeSinglePeerings, typeDualPeerings } from '../../networking/virtual-network/module.type.bicep'
import { typeFrontendListener, typeBackendPool, typeRewriteRuleset } from '../../networking/application-gateway/module.types.bicep'

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

  virtualNetwork: {
    naming: typeNaming?

    @description('Should be an /24 address space. If not, then define a custom subnet address prefix, otherwise it will fail.')
    addressSpace: string
    subnet: {
      appgateway: {
        addressPrefix: string
      }
    }?

    @description('Configures only peering on the source network. The peering on the remote network must be configured separately.')
    singlePeerings: typeSinglePeerings[]?

    @description('Configures both peerings at once.')
    dualPeerings: typeDualPeerings[]?

    diagnosticSettings: typeDiagnosticSettings
  }?

  // This is from the App Gateway module and maintained in the App Gateway module.
  // Defining it here for nice auto-completion and documentation.
  // Some of the properties are left out, beacuse they are already deployed as part of this solution.

  //@description('The key vault for reading certificates and secrets.')
  //keyVault: {
  //  id: string
  //  @description('If this is true, the module attemps to deploy a role assignment on the key vault.')
  //  deployRoleAssignment: bool?
  //}

  @description('The SKU configuration for the application gateway.')
  sku: {
    name: 'Standard_v2' | 'WAF_v2'
    tier: 'Standard_v2' | 'WAF_v2'
    capacity: int?
  }?

  backendPool: typeBackendPool

  frontendListener: typeFrontendListener

  rewriteRuleSet: typeRewriteRuleset

  diagnosticSettings: typeDiagnosticSettings
}

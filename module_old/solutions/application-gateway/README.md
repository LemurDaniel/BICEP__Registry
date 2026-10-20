# Solution: Application Gateway

This module deploys an application gateway with all required resources either in a preexistent resource group or with a created resource group at the subscription scope.

## Resources

- **Application Gateway**
  - Handles traffic.

- **Virtual Network**
  - Provides connectivity for the application gateway and backend pools.

- **Key Vault**
  - Manages and stores certificates for custom domains.

- **Managed Identity**
  - Grants read permission for the application gateway to access certificates from the key vault.

## TODOS/IDEAS

- Add peering options for backend virtual networks.

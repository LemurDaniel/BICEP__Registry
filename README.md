# Bicep Module Registry

> [!NOTE]
> AI disclaimer: Originally written by hand, then improved with the help of AI. 🤖

A collection of reusable Azure Bicep modules, published to an Azure Container Registry (ACR). The registry itself is deployed via Bicep from the `infra/` folder.

## Repository layout

| Path | Content |
|------|---------|
| `modules/resources/` | Single-resource or tightly-grouped-resource modules |
| `modules/patterns/` | Multi-resource architectural patterns |
| `modules/utility/` | Pure logic helpers (naming, switch functions, type exports, ...) |
| `infra/` | Bicep for the ACR registry (subscription and resource group scope) |
| `.scripts/` | Helper scripts for deployment and offline checks |
| `.github/workflows/` | CI/CD for dev and prod |

Each module contains a `module.bicep`, a `version.json` and an `example/` folder with `module.bicep` + `module.bicepparam` used for test deployments.

## Using a module

```bicep
module example 'br:<registry>.azurecr.io/modules/utility/switch:1.0.0' = {
  name: 'example'
}
```

Replace `<registry>` with your ACR name and use the module path and version you need.

## Publishing

Publishing is driven by `version.json`. Bumping the version of a module is what triggers CI to verify and publish it.

- `dev` branch publishes to the dev registry
- `master` branch publishes to the prod registry
- Pull requests and manual runs publish with an `unreleased/` prefix

## Local checks

```powershell
# Offline: builds every module and example, validates every version.json
pwsh .scripts/Test-Modules.ps1

# Dry run against Azure
. .scripts/deploy.ps1 -WhatIf -FolderPrefix "modules/" -ModulePath "utility/switch" -Location "westeurope"
```

## CI configuration

- Secret `AZURE_AUTH`: JSON with OIDC or client secret credentials
- Variables `REGISTRY_NAME` and `DEFAULT_LOCATION`

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A **Bicep module registry** — a collection of reusable Azure Bicep modules published to an Azure Container Registry (ACR). The registry itself is also deployed via Bicep in the `infra/` folder.

## Module structure

Each module lives under `modules/<category>/<module-name>/` and must contain:

- `module.bicep` — the module entry point (the file that gets published to ACR)
- `version.json` — version and deployment test configuration
- `example/` — one or more folders each containing `module.bicep` + `module.bicepparam` used for CI test deployments

Three module categories:
- `modules/resources/` — single-resource or tightly-grouped-resource modules
- `modules/patterns/` — multi-resource architectural patterns (can wrap Azure Verified Modules)
- `modules/utility/` — pure logic helpers (name generation, type exports, switch functions, etc.)

### version.json format

```json
{
  "version": "1.0.0",
  "description": "Human-readable description",
  "deployment_tests": {
    "base_path": ".",
    "include": [
      { "description": "...", "pattern": "example*" }
    ]
  }
}
```

The `deployment_tests.include[].pattern` controls which subdirectories under `base_path` are deployed during CI verification. Changing `version.json` (incrementing version or modifying content) is what **triggers CI to detect a module as changed** and publish it.

## CI/CD pipeline

### Change detection

The pipeline detects changed modules by comparing `version.json` files:
- On **pull requests**: git diff between source and target branch (PRs ignore changes under `modules/**/example/**` and `README.md`; pushes do not)
- On **push/merge**: git diff from the `meta-last-publish-marker-<branch>` git tag to HEAD (if no tag exists, all modules are treated as changed)

After a successful publish, the `tmpl.bicep.setChangeMarker` action updates this tag.

### Environments

Dev and prod are separate workflows on separate branches: `dev` branch → dev registry (default `acrsampledev`), `master` branch → prod registry (default `acrbicepregprodfzh`). They differ in two ways: prod also runs test deployments on push, and only dev opens runner IP rules on the registry.

### Module lifecycle per CI run

1. **Detect changes** — finds modules with modified `version.json`
2. **Verify** (PR / workflow_dispatch; prod also on push) — runs `az bicep publish` as a what-if, then actual test deployments using `.scripts/deploy.ps1`
3. **Publish** (push / workflow_dispatch) — publishes `module.bicep` to ACR as `br:<registry>.azurecr.io/<module-path>:<version>`

Concurrency is limited (default 5 modules per run). Exceeding this requires explicitly increasing `concurrency_limit`.

### Workflow files

| File | Purpose |
|------|---------|
| `.github/workflows/publish.bicep.modules.dev.yaml` | Main orchestrator for dev modules |
| `.github/workflows/publish.bicep.modules.prod.yaml` | Main orchestrator for prod modules |
| `.github/workflows/tmpl.bicep.module.verify.pwsh.yaml` | Template: test-deploy a module |
| `.github/workflows/tmpl.bicep.module.publish.pwsh.yaml` | Template: publish a module to ACR |
| `.github/workflows/deploy.infra.dev.yaml` | Deploy the registry infrastructure (dev) |
| `.github/workflows/deploy.infra.prod.yaml` | Deploy the registry infrastructure (prod) |

### Required GitHub secret

`AZURE_AUTH` — JSON object with either OIDC or ClientSecret auth:
```json
{ "auth_type": "OIDC", "tenantId": "...", "subscriptionId": "...", "clientId": "..." }
```

### Required GitHub variables

- `REGISTRY_NAME` — ACR name (e.g. `acrsampledev`)
- `DEFAULT_LOCATION` — Azure region (e.g. `westeurope`)

## Local testing

Test a module deployment locally with PowerShell (requires `az` CLI and Azure login):

```powershell
# What-if (dry run)
. .scripts/deploy.ps1 -WhatIf -FolderPrefix "modules/" -ModulePath "utility/switch" -Location "westeurope"

# Actual deployment
. .scripts/deploy.ps1 -FolderPrefix "modules/" -ModulePath "utility/switch" -Location "westeurope"
```

The script reads `version.json` to discover which `example*` subdirectories to deploy, auto-detects `targetScope` (subscription or resourceGroup), and names deployments as `module.<path>.<index>`.

## Infrastructure deployment

The ACR registry itself is deployed from `infra/`:
- `registry.scope.subscription.bicep` — subscription-scoped entry point (creates RG + delegates to the RG-scoped module)
- `registry.scope.resource_group.bicep` — actual ACR resource definition
- `infra/params/` — environment-specific parameter files (`.test.bicepparam`, `.prod.bicepparam`)
- Prod infra deploys use the GitHub environment `prod`: add required reviewers there for an approval gate. All workflows grant `id-token: write` so OIDC login works.

## Key conventions

- Module images in ACR are versioned from `version.json`. Bumping the version is the only way to trigger a new publish.
- Any run that is not a push (PR, workflow_dispatch) publishes images with an `unreleased/` prefix (`IMAGE_PREFIX`).
- IP rules on private registries are temporarily opened for the GitHub Actions runner IP, then removed — even on failure (`always()` condition).
- The `utility/switch` module exports typed switch functions (`switchStr`, `switchInt`, `switchArr`, `switch`) imported via Bicep's `import` statement — not deployed as ARM resources, purely compile-time logic.

## Offline check

`pwsh .scripts/Test-Modules.ps1` runs `az bicep build` on every `module.bicep` and example, and validates every `version.json`. It never touches Azure. `/check-modules` wraps it for use with `/loop`.

## Gotchas / hard limits

- Do not edit or bump `version.json` unless asked: any change triggers a publish on the next CI run.
- Do not run `deploy.ps1` without `-WhatIf`, or any `az deployment` / `az acr` / `az bicep publish` command, without explicit confirmation. These are denied in `.claude/settings.json`.
- Never create, move or delete `meta-last-publish-marker-*` tags. Deleting one makes the next push publish all modules.
- Do not raise `concurrency_limit` unless asked.
- Never commit `AZURE_AUTH` contents or anything from `.claude/state/`.



<#

    This is a script for test deploying the module and verifying it works as expected.

    This script is also run in the CI/CD pipeline, to test the functionality of the module.

#>


<#

# Optionally login to azure
Connect-AzAccount

# Optionally set the context the subscription
Set-AzContext -Subscription <subscrptionId>

#>

$deployment = $null
$location = 'Westeurope'
$templateFile = "./module.bicep"
$parameterFile = "./module.bicepparam"
$deploymentName = "module-registry.param-utility"

$targetScope = Get-Content -Path $templateFile | Select-String targetScope -Raw
if ($targetScope -LIKE "*'subscription'*") {
    $targetScope = 'subscription'
}
else {
    $targetScope = 'resourceGroup'
}

Write-Host -ForegroundColor Magenta ""
Write-Host -ForegroundColor Magenta ""

Write-Host -ForegroundColor Magenta "------------------------------------------------------"
Write-Host -ForegroundColor Magenta "Deploying $deploymentName"


if ($targetScope -EQ 'resourceGroup') {
    New-AzResourceGroup -Name $deploymentName -Location $location -Force

    if ($WhatIf.IsPresent) {
        $Deployment = @{
            Name                    = $deploymentName
            ResourceGroupName       = $deploymentName
            TemplateFile            = $templateFile
            TemplateParameterFile   = $parameterFile
            WhatIfResultFormat      = 'FullResourcePayloads'
            WhatIfExcludeChangeType = 'NoChange' # Ignore | NoChange | Deploy | Create | Modify | Delete
        }
        $deployment = New-AzResourceGroupDeployment @Deployment -WhatIf -Verbose
    }
    else {
        $Deployment = @{
            Name                  = $deploymentName
            ResourceGroupName     = $deploymentName
            TemplateFile          = $templateFile
            TemplateParameterFile = $parameterFile
            DenySettingsMode      = 'None' # None, DenyDelete, DenyWriteAndDelete
            ActionOnUnmanage      = 'DeleteAll' # DetachAll, DeleteResources, DeleteAll
        }
        $deployment = New-AzResourceGroupDeploymentStack @Deployment -Verbose -Force -Confirm:$false
    }
} 

elseif ($targetScope -EQ 'subscription') {

    if ($WhatIf.IsPresent) {
        $Deployment = @{
            Name                    = $deploymentName
            Location                = $location
            TemplateFile            = $templateFile
            TemplateParameterFile   = $parameterFile
            WhatIfResultFormat      = 'FullResourcePayloads'
            WhatIfExcludeChangeType = 'NoChange' # Ignore | NoChange | Deploy | Create | Modify | Delete
        }
        $deployment = New-AzSubscriptionDeployment @Deployment -WhatIf -Verbose
    }
    else {
        $Deployment = @{
            Name                  = $deploymentName
            Location              = $location
            TemplateFile          = $templateFile
            TemplateParameterFile = $parameterFile
            DenySettingsMode      = 'None' # None, DenyDelete, DenyWriteAndDelete
            ActionOnUnmanage      = 'DeleteAll' # DetachAll, DeleteResources, DeleteAll
        }
        $deployment = New-AzSubscriptionDeploymentStack @Deployment -Verbose -Force -Confirm:$false
    }
}

else {
    throw [System.InvalidOperationException]::new("Invalid TargetScope $targetScope")
}

$deployment

Write-Host ($Deployment.outputs | ConvertTo-Json)
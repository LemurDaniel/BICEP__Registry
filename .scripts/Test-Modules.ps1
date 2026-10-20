<#

Offline check of all modules: bicep build and version.json validation.
Does not touch Azure. Exit code 1 when any check fails.

#>

param(
    [Parameter()]
    [System.String]
    $FolderPrefix = "modules/"
)

$failures = @()

$versionFiles = Get-ChildItem -Path $FolderPrefix -Recurse -Filter version.json

foreach ($versionFile in $versionFiles) {
    $moduleDir = $versionFile.DirectoryName
    $name = Resolve-Path -Path $moduleDir -Relative

    try {
        $json = Get-Content -Path $versionFile.FullName -Raw | ConvertFrom-Json
    } catch {
        $failures += "$name | version.json is not valid JSON"
        continue
    }

    if ($json.version -notmatch '^\d+\.\d+\.\d+$') {
        $failures += "$name | version.json has no valid semver 'version'"
    }

    if (-not (Test-Path "$moduleDir/module.bicep")) {
        $failures += "$name | module.bicep is missing"
        continue
    }

    $bicepFiles = @(Get-Item "$moduleDir/module.bicep")
    $basePath = $json.deployment_tests.base_path ?? "."
    $bicepFiles += Get-ChildItem -Path "$moduleDir/$basePath" -Directory
    | Where-Object { $_.Name -like "example*" }
    | ForEach-Object { Get-ChildItem -Path $_.FullName -Filter module.bicep }

    foreach ($bicepFile in $bicepFiles) {
        $output = az bicep build --file $bicepFile.FullName --stdout 2>&1
        if ($LASTEXITCODE -ne 0) {
            $failures += "$name | bicep build failed for $($bicepFile.FullName)`n$output"
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host -ForegroundColor Red $_ }
    Write-Host -ForegroundColor Red "$($failures.Count) check(s) failed"
    exit 1
}

Write-Host -ForegroundColor Green "All $($versionFiles.Count) modules passed"

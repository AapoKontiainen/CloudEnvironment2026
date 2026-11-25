$ErrorActionPreference = 'Stop'

$ResourceGroup = 'rg-cloud26-aapo-dev'
$TemplateFile = Join-Path $PSScriptRoot 'main.bicep'
$ParametersFile = Join-Path $PSScriptRoot 'dev.bicepparam'
$DeploymentName = 'main'

if ([string]::IsNullOrWhiteSpace($env:POSTGRES_ADMIN_PASSWORD)) {
    $securePassword = Read-Host 'PostgreSQL password' -AsSecureString
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try {
        $env:POSTGRES_ADMIN_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
}

& az account show --only-show-errors | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Azure CLI is not authenticated. Run "az login" and try again.'
}

Write-Host 'Previewing deployment changes...' -ForegroundColor Cyan
& az deployment group what-if `
    --resource-group $ResourceGroup `
    --template-file $TemplateFile `
    --parameters $ParametersFile
if ($LASTEXITCODE -ne 0) {
    throw 'What-if failed. Deployment was not started.'
}

$confirmation = Read-Host 'Deploy? (y/n)'
if ($confirmation -ne 'y') {
    Write-Host 'Deployment cancelled.' -ForegroundColor Yellow
    exit 0
}

Write-Host 'Deploying...' -ForegroundColor Cyan
& az deployment group create `
    --name $DeploymentName `
    --resource-group $ResourceGroup `
    --template-file $TemplateFile `
    --parameters $ParametersFile `
    --only-show-errors | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Deployment failed.'
}

$outputsJson = & az deployment group show `
    --name $DeploymentName `
    --resource-group $ResourceGroup `
    --query properties.outputs `
    --output json `
    --only-show-errors
if ($LASTEXITCODE -ne 0) {
    throw 'Deployment succeeded, but its outputs could not be read.'
}

$outputs = $outputsJson | ConvertFrom-Json
Write-Host "Web app URL: $($outputs.webAppUrl.value)"
Write-Host "PostgreSQL server FQDN: $($outputs.postgresServerFqdn.value)"
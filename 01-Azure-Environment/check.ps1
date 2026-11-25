$YourName = "aapo"
$ResourceGroup = "rg-cloud26-$YourName-dev"
$AppName = "app-cloud26-$YourName-dev"

$ErrorActionPreference = "Stop"

Write-Host "Active subscription:" -ForegroundColor Cyan
az account show --query "{name:name,id:id}" --output table
if ($LASTEXITCODE -ne 0) {
    Write-Error "Azure CLI is not signed in. Run 'az login' and try again."
    exit 1
}

$resourceGroupExists = az group exists --name $ResourceGroup
if ($LASTEXITCODE -ne 0) {
    Write-Error "Could not check resource group '$ResourceGroup'."
    exit 1
}

if ($resourceGroupExists -ne "true") {
    Write-Host "Resource group '$ResourceGroup' does not exist." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nResources in ${ResourceGroup}:" -ForegroundColor Cyan
az resource list --resource-group $ResourceGroup `
    --query "[].{Name:name,Type:type,Location:location}" `
    --output table

Write-Host "`nResource tags:" -ForegroundColor Cyan
az resource list --resource-group $ResourceGroup `
    --query "[].{Name:name,Tags:tags}" `
    --output json

$webAppExists = az webapp show `
    --name $AppName `
    --resource-group $ResourceGroup `
    --query name `
    --output tsv 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($webAppExists)) {
    Write-Host "`nWeb app '$AppName' does not exist." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nWeb app status and URL:" -ForegroundColor Cyan
az webapp show `
    --name $AppName `
    --resource-group $ResourceGroup `
    --query "{Status:state,URL:defaultHostName}" `
    --output table

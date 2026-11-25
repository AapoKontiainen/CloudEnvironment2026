# Cloud 26 base environment provisioning script.
# Safe to run repeatedly: existing resources are updated, not duplicated.

$YourName = "aapo"
$YourEmail = "kontiainenape@gmail.com"

$Location = "swedencentral"
$ResourceGroup = "rg-cloud26-$YourName-dev"
$AppName = "app-cloud26-$YourName-dev"
$PlanName = "plan-cloud26-$YourName-dev"
$ProjectPath = Join-Path $PSScriptRoot "StarterCode\CampusEvents"

$Tags = @(
    "Application=cloud26"
    "Environment=dev"
    "Owner=$YourEmail"
    "Course=Cloud26"
)

$TagSettings = @(
    "tags.Application=cloud26"
    "tags.Environment=dev"
    "tags.Owner=$YourEmail"
    "tags.Course=Cloud26"
)

$ErrorActionPreference = "Stop"

# Confirm that Azure CLI has an authenticated account.
az account show --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "You are not signed in. Run 'az login' and then run this script again."
    exit 1
}

# Create the resource group only when it does not already exist.
$resourceGroupExists = az group exists --name $ResourceGroup
if ($resourceGroupExists -ne "true") {
    az group create `
        --name $ResourceGroup `
        --location $Location `
        --tags $Tags `
        --output none
}

# Deploy from the project directory. az webapp up creates or updates the app and plan.
if (-not (Test-Path (Join-Path $ProjectPath "CampusEvents.csproj"))) {
    Write-Error "CampusEvents project was not found at '$ProjectPath'."
    exit 1
}

Push-Location $ProjectPath
try {
    az webapp up `
        --name $AppName `
        --resource-group $ResourceGroup `
        --plan $PlanName `
        --location $Location `
        --sku F1 `
        --os-type Linux `
        --runtime "DOTNETCORE:10.0" `
        --output none
}
finally {
    Pop-Location
}

# Apply the common tags to both App Service resources.
az webapp update `
    --name $AppName `
    --resource-group $ResourceGroup `
    --set $TagSettings `
    --output none

az appservice plan update `
    --name $PlanName `
    --resource-group $ResourceGroup `
    --set $TagSettings `
    --output none

# Print the deployed URL.
$HostName = az webapp show `
    --name $AppName `
    --resource-group $ResourceGroup `
    --query defaultHostName `
    --output tsv

Write-Host "Environment ready: https://$HostName"

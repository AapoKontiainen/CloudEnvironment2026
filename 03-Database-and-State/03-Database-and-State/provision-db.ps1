# Ensures the PostgreSQL server, firewall rules, App Service settings,
# storage account, and posters container exist. Safe to run repeatedly.

$YourName = "aapo"
$YourEmail = "kontiainen@gmail.com"

$Location = "swedencentral"
$ResourceGroup = "rg-cloud26-$YourName-dev"
$AppName = "app-cloud26-$YourName-dev"
$PgServer = "pg-cloud26-$YourName-ne"
$PgAdmin = "campusadmin"
$DatabaseName = "campusevents"
$StorageAccount = "stcloud26${YourName}dev123"

$ErrorActionPreference = "Stop"

function Convert-SecureStringToPlainText {
    param([Security.SecureString]$SecureString)

    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

az account show --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "You are not signed in. Run 'az login' and try again."
    exit 1
}

$resourceGroupExists = az group exists --name $ResourceGroup
if ($LASTEXITCODE -ne 0 -or $resourceGroupExists -ne "true") {
    Write-Error "Resource group '$ResourceGroup' was not found. Run provision.ps1 first."
    exit 1
}

$server = az postgres flexible-server show `
    --resource-group $ResourceGroup `
    --name $PgServer `
    --output json 2>$null | ConvertFrom-Json

if ($server) {
    Write-Host "Flexible Server '$PgServer' already exists; skipping creation." -ForegroundColor Yellow
    if ($server.state -eq "Stopped") {
        Write-Host "Flexible Server is stopped; starting it..." -ForegroundColor Cyan
        az postgres flexible-server start `
            --resource-group $ResourceGroup `
            --name $PgServer `
            --output none
    }
}
else {
    $passwordSecure = Read-Host "Choose the PostgreSQL admin password" -AsSecureString
    $password = Convert-SecureStringToPlainText $passwordSecure

    Write-Host "Creating Flexible Server '$PgServer'..." -ForegroundColor Cyan
    az postgres flexible-server create `
        --resource-group $ResourceGroup `
        --name $PgServer `
        --location $Location `
        --tier Burstable `
        --sku-name Standard_B1ms `
        --storage-size 32 `
        --version 16 `
        --admin-user $PgAdmin `
        --admin-password $password `
        --public-access 0.0.0.0 `
        --tags Application=cloud26 Environment=dev Owner=$YourEmail Course=Cloud26 `
        --yes `
        --output none

    if ($LASTEXITCODE -ne 0) {
        Write-Error "PostgreSQL Flexible Server creation failed."
        exit 1
    }

    Write-Host "Flexible Server created." -ForegroundColor Green
}

$database = az postgres flexible-server db show `
    --resource-group $ResourceGroup `
    --server-name $PgServer `
    --name $DatabaseName `
    --output json 2>$null | ConvertFrom-Json

if ($database) {
    Write-Host "Database '$DatabaseName' already exists; skipping creation." -ForegroundColor Yellow
}
else {
    az postgres flexible-server db create `
        --resource-group $ResourceGroup `
        --server-name $PgServer `
        --name $DatabaseName `
        --output none
    Write-Host "Database '$DatabaseName' created." -ForegroundColor Green
}

$myIp = (Invoke-RestMethod "https://api.ipify.org").Trim()
az postgres flexible-server firewall-rule create `
    --resource-group $ResourceGroup `
    --server-name $PgServer `
    --name AllowAzureServices `
    --start-ip-address 0.0.0.0 `
    --end-ip-address 0.0.0.0 `
    --output none

az postgres flexible-server firewall-rule create `
    --resource-group $ResourceGroup `
    --server-name $PgServer `
    --name MyDevMachine `
    --start-ip-address $myIp `
    --end-ip-address $myIp `
    --output none
Write-Host "PostgreSQL firewall rules ensured." -ForegroundColor Green

if (-not $passwordSecure) {
    $passwordSecure = Read-Host "Enter the existing PostgreSQL admin password for the App Service setting" -AsSecureString
}
$password = Convert-SecureStringToPlainText $passwordSecure
$postgresHost = "$PgServer.postgres.database.azure.com"
$databaseConnectionString = "Host=$postgresHost;Port=5432;Database=$DatabaseName;Username=$PgAdmin;Password=$password;SSL Mode=Require"

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --settings "ConnectionStrings__DefaultConnection=$databaseConnectionString" `
    --output none
Write-Host "App Service PostgreSQL connection setting ensured." -ForegroundColor Green

$storage = az storage account show `
    --resource-group $ResourceGroup `
    --name $StorageAccount `
    --output json `
    2>$null |
    ConvertFrom-Json

if ($storage) {
    Write-Host "Storage account '$StorageAccount' already exists; skipping creation." -ForegroundColor Yellow
}
else {
    az storage account create `
        --resource-group $ResourceGroup `
        --name $StorageAccount `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --allow-blob-public-access false `
        --min-tls-version TLS1_2 `
        --tags Application=cloud26 Environment=dev Owner=$YourEmail Course=Cloud26 `
        --output none
    Write-Host "Storage account '$StorageAccount' created." -ForegroundColor Green
}

az storage container create `
    --account-name $StorageAccount `
    --name posters `
    --auth-mode key `
    --output none

$storageConnectionString = az storage account show-connection-string `
    --resource-group $ResourceGroup `
    --name $StorageAccount `
    --query connectionString `
    --output tsv

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --settings "ConnectionStrings__Storage=$storageConnectionString" `
    --output none
Write-Host "Storage account and 'posters' container ensured." -ForegroundColor Green

Write-Host ""
Write-Host "Database environment ready." -ForegroundColor Green
Write-Host "Verify: https://$AppName.azurewebsites.net/health"
Write-Host "When finished, stop the database to avoid compute charges:"
Write-Host "az postgres flexible-server stop --resource-group $ResourceGroup --name $PgServer"

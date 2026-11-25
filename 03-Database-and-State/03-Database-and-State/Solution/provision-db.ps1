# =============================================================
# Assignment 3 — Model solution: idempotent database provisioning
# (Independent Exercise 3)
#
# Ensures the PostgreSQL Flexible Server, its firewall rules,
# the storage account + posters container (guided section G) and
# the App Service connection strings exist. Safe to run repeatedly:
# existing resources are detected and skipped.
#
# Usage:
#   .\provision-db.ps1
#   (prompts for the DB admin password — it is never stored in a file)
# =============================================================

# ----- 1. Variables: EDIT THESE -----------------------------
$YourName  = "matti"                    # lowercase, no special characters — same as Assignment 1

# Derived names (course naming convention)
$Location      = "northeurope"
$ResourceGroup = "rg-cloud26-$YourName-dev"
$AppName       = "app-cloud26-$YourName-dev"
$PgServer      = "pg-cloud26-$YourName-dev"
$PgAdmin       = "campusadmin"
$DbName        = "campusevents"
$StorageName   = "stcloud26${YourName}dev"   # storage names: no hyphens!

# ----- 2. Preconditions --------------------------------------
# Signed in to Azure?
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not signed in. Run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "Signed in as: $($account.user.name)" -ForegroundColor Green

# Resource group must exist (Assignment 1 created it)
if ((az group exists --name $ResourceGroup) -ne "true") {
    Write-Host "Resource group '$ResourceGroup' not found. Run the Assignment 1 provision.ps1 first." -ForegroundColor Red
    exit 1
}

# ----- 3. PostgreSQL Flexible Server (idempotent) ------------
# 'az postgres flexible-server create' is NOT idempotent, so check first.
$existing = az postgres flexible-server show `
    --resource-group $ResourceGroup `
    --name $PgServer 2>$null | ConvertFrom-Json

if ($existing) {
    Write-Host "Flexible Server '$PgServer' already exists (state: $($existing.state)) — skipping creation." -ForegroundColor Yellow

    # If it was stopped (e.g. end of a previous session), start it.
    if ($existing.state -eq "Stopped") {
        Write-Host "Server is stopped — starting it..." -ForegroundColor Cyan
        az postgres flexible-server start --resource-group $ResourceGroup --name $PgServer | Out-Null
    }

    # Password is only needed when (re)writing the connection string below.
    $PgPasswordSecure = Read-Host "Enter the existing DB admin password (for the App Service setting)" -AsSecureString
}
else {
    # Prompt for the password at run time — never hard-code it in the script.
    $PgPasswordSecure = Read-Host "Choose a strong DB admin password" -AsSecureString

    Write-Host "Creating Flexible Server '$PgServer' (Burstable B1ms, 32 GB, PostgreSQL 16)..." -ForegroundColor Cyan
    Write-Host "This takes 5-10 minutes." -ForegroundColor Cyan

    az postgres flexible-server create `
        --resource-group $ResourceGroup `
        --name $PgServer `
        --location $Location `
        --tier Burstable `
        --sku-name Standard_B1ms `
        --storage-size 32 `
        --version 16 `
        --admin-user $PgAdmin `
        --admin-password (ConvertFrom-SecureString $PgPasswordSecure -AsPlainText) `
        --public-access 0.0.0.0 `
        --tags Environment=dev Course=cloud26 Owner=$YourName `
        --yes | Out-Null

    az postgres flexible-server db create `
        --resource-group $ResourceGroup `
        --server-name $PgServer `
        --name $DbName | Out-Null

    Write-Host "Flexible Server created." -ForegroundColor Green
}

# ----- 4. Firewall rules (idempotent) ------------------------
# 'firewall-rule create' overwrites an existing rule with the same
# name, so it is safe to run every time.

# Allow Azure services (App Service) — the special 0.0.0.0 rule.
az postgres flexible-server firewall-rule create `
    --resource-group $ResourceGroup `
    --server-name $PgServer `
    --name AllowAzureServices `
    --start-ip-address 0.0.0.0 `
    --end-ip-address 0.0.0.0 | Out-Null
Write-Host "Firewall: AllowAzureServices ensured." -ForegroundColor Green

# Allow the machine running this script (IP may change between runs —
# re-running the script simply updates the rule).
$MyIp = (Invoke-RestMethod "https://api.ipify.org")
az postgres flexible-server firewall-rule create `
    --resource-group $ResourceGroup `
    --server-name $PgServer `
    --name MyDevMachine `
    --start-ip-address $MyIp `
    --end-ip-address $MyIp | Out-Null
Write-Host "Firewall: MyDevMachine ensured ($MyIp)." -ForegroundColor Green

# ----- 5. App Service connection string (idempotent) ---------
# 'appsettings set' overwrites the value, so running twice is fine.
$PgPassword = ConvertFrom-SecureString $PgPasswordSecure -AsPlainText
$ConnString = "Host=$PgServer.postgres.database.azure.com;Database=$DbName;Username=$PgAdmin;Password=$PgPassword;Ssl Mode=Require"

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --settings ConnectionStrings__DefaultConnection=$ConnString | Out-Null
Write-Host "App Service connection string ensured (app restarts automatically)." -ForegroundColor Green

# ----- 6. Storage account + posters container (idempotent) ----
# 'storage account create' IS idempotent for an identical config,
# but check first anyway so the output tells the truth.
$storageExists = az storage account show `
    --name $StorageName `
    --resource-group $ResourceGroup 2>$null | ConvertFrom-Json

if ($storageExists) {
    Write-Host "Storage account '$StorageName' already exists — skipping creation." -ForegroundColor Yellow
}
else {
    Write-Host "Creating storage account '$StorageName'..." -ForegroundColor Cyan
    az storage account create `
        --name $StorageName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --allow-blob-public-access false `
        --min-tls-version TLS1_2 `
        --tags Environment=dev Course=cloud26 Owner=$YourName | Out-Null
    Write-Host "Storage account created." -ForegroundColor Green
}

# 'container create' returns created=false if it already exists — safe to run every time.
az storage container create `
    --name posters `
    --account-name $StorageName `
    --auth-mode key | Out-Null
Write-Host "Container 'posters' ensured." -ForegroundColor Green

# Storage connection string for the app (overwrites, so idempotent).
$StorageConn = az storage account show-connection-string `
    --name $StorageName `
    --resource-group $ResourceGroup `
    --query connectionString --output tsv

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --settings ConnectionStrings__Storage=$StorageConn | Out-Null
Write-Host "App Service storage connection string ensured." -ForegroundColor Green

# ----- 7. Summary ---------------------------------------------
$server = az postgres flexible-server show `
    --resource-group $ResourceGroup `
    --name $PgServer `
    --query "{state:state, sku:sku.name, storageGb:storage.storageSizeGb, version:version}" | ConvertFrom-Json

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host "Server:   $PgServer ($($server.state), $($server.sku), $($server.storageGb) GB, PostgreSQL $($server.version))"
Write-Host "Database: $DbName"
Write-Host "Storage:  $StorageName (container: posters)"
Write-Host "App:      https://$AppName.azurewebsites.net/health  <- verify this says Healthy"
Write-Host ""
Write-Host "Cost reminder: the server bills while it runs. When you stop working:" -ForegroundColor Yellow
Write-Host "  az postgres flexible-server stop --resource-group $ResourceGroup --name $PgServer" -ForegroundColor Yellow

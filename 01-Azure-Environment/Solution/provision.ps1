# ============================================================
# Exercise 1 — Provisioning script (model answer)
#
# Creates the Cloud 26 base environment idempotently:
#   1. Verifies you are signed in to Azure CLI
#   2. Creates the resource group with tags (if missing)
#   3. Deploys CampusEvents with az webapp up (F1, .NET 10)
#   4. Sets tags on the web app and app service plan
#   5. Prints the web app URL
#
# Safe to run multiple times — nothing is duplicated.
#
# Usage:
#   .\provision.ps1
#   (uses $PSScriptRoot, so it works no matter where you run it from)
# ============================================================

# ----- 1. Variables: EDIT THESE -----------------------------
$YourName  = "matti"                    # lowercase, no special characters
$YourEmail = "matti.m@edu.xamk.fi"      # school email (Owner tag)

# Derived names (course naming convention)
$Location     = "northeurope"
$ResourceGroup = "rg-cloud26-$YourName-dev"
$AppName       = "app-cloud26-$YourName-dev"
$PlanName      = "plan-cloud26-$YourName-dev"
$ProjectPath   = Join-Path $PSScriptRoot "..\StarterCode\CampusEvents"

# Tags in two formats: CLI list (create) and --set list (update)
$TagList = "Application=cloud26", "Environment=dev", "Owner=$YourEmail", "Course=Cloud26"
$TagSet  = "tags.Application=cloud26", "tags.Environment=dev", "tags.Owner=$YourEmail", "tags.Course=Cloud26"

$ErrorActionPreference = "Stop"

# ----- 2. Check sign-in --------------------------------------
Write-Host "Checking Azure CLI sign-in..." -ForegroundColor Cyan

# 'az account show' fails (non-zero exit code) when not signed in.
az account show --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "You are not signed in. Run 'az login' first, then re-run this script." -ForegroundColor Red
    exit 1
}

$subscriptionName = az account show --query name --output tsv
Write-Host "Signed in. Active subscription: $subscriptionName" -ForegroundColor Green

# ----- 3. Resource group (idempotent) ------------------------
Write-Host "Checking resource group '$ResourceGroup'..." -ForegroundColor Cyan

$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "true") {
    Write-Host "Resource group already exists - skipping creation." -ForegroundColor Yellow
}
else {
    Write-Host "Creating resource group..." -ForegroundColor Cyan
    az group create 
        --name $ResourceGroup 
        --location $Location 
        --tags $TagList 
        --output none
    Write-Host "Resource group created." -ForegroundColor Green
}

# ----- 4. Deploy the app (idempotent) -------------------------
# 'az webapp up' creates the plan and web app on first run and
# just redeploys the code on later runs - idempotent by design.
if (-not (Test-Path (Join-Path $ProjectPath "CampusEvents.csproj"))) {
    Write-Host "CampusEvents project not found at: $ProjectPath" -ForegroundColor Red
    Write-Host "Check that StarterCode/CampusEvents exists next to the Solution folder." -ForegroundColor Red
    exit 1
}

Write-Host "Deploying CampusEvents (this can take a few minutes)..." -ForegroundColor Cyan

Push-Location $ProjectPath
try {
    az webapp up 
        --name $AppName 
        --resource-group $ResourceGroup 
        --plan $PlanName 
        --location $Location 
        --sku F1 
        --os-type Linux 
        --runtime "DOTNETCORE:10.0" 
        --output none
}
finally {
    Pop-Location
}

Write-Host "Deployment finished." -ForegroundColor Green

# ----- 5. Tags on app resources (idempotent) ------------------
# Setting the same tag values again is harmless, so no existence
# checks are needed here.
Write-Host "Setting tags on the web app and plan..." -ForegroundColor Cyan

az webapp update 
    --name $AppName 
    --resource-group $ResourceGroup 
    --set $TagSet 
    --output none

az appservice plan update 
    --name $PlanName 
    --resource-group $ResourceGroup 
    --set $TagSet 
    --output none

Write-Host "Tags set." -ForegroundColor Green

# ----- 6. Print the result -----------------------------------
$appUrl = az webapp show 
    --name $AppName 
    --resource-group $ResourceGroup 
    --query defaultHostName 
    --output tsv

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host " Environment ready!" -ForegroundColor Green
Write-Host " App URL:    https://$appUrl" -ForegroundColor Green
Write-Host " Health:     https://$appUrl/health" -ForegroundColor Green
Write-Host " Events API: https://$appUrl/api/events" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

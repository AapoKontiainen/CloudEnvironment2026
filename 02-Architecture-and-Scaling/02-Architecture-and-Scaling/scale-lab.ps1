# Campus Events scale-out experiment.
# Review each Azure resource mutation before running this script.

# ----- Variables: edit the <your-name> values -----------------
$ResourceGroup = "rg-cloud26-aapo-dev"
$AppName       = "app-cloud26-aapo-dev"
$PlanName      = "plan-cloud26-aapo-dev"
$BaseUrl       = "https://app-cloud26-aapo-dev.azurewebsites.net"

$EventId       = "22222222-2222-2222-2222-222222222222"
$AttendeeName  = "Scale Lab Test"
$AttendeeEmail = "scale-lab@example.com"

$ErrorActionPreference = "Stop"
$registrationUrl = "$BaseUrl/api/events/$EventId/registrations"
$eventUrl = "$BaseUrl/api/events/$EventId"

try {
    # 1. Scale the App Service plan up to B1.
    az appservice plan update `
        --name $PlanName `
        --resource-group $ResourceGroup `
        --sku B1 `
        --output none
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to scale plan '$PlanName' to B1."
    }

    # 2. Disable ARR client affinity so requests can reach either instance.
    az webapp update `
        --name $AppName `
        --resource-group $ResourceGroup `
        --client-affinity-enabled false `
        --output none
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to disable client affinity for '$AppName'."
    }

    # 3. Scale the App Service plan out to two workers.
    az appservice plan update `
        --name $PlanName `
        --resource-group $ResourceGroup `
        --number-of-workers 2 `
        --output none
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to set two workers on plan '$PlanName'."
    }

    # 4. Wait up to five minutes for two instance rows, without inventing a name.
    Write-Host "Waiting for two App Service instances (up to five minutes)..." -ForegroundColor Cyan
    $deadline = (Get-Date).AddMinutes(5)
    $instanceTable = @()
    $instanceRowCount = 0

    do {
        $instanceTable = @(az webapp list-instances `
            --name $AppName `
            --resource-group $ResourceGroup `
            --output table)
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to list instances for '$AppName'."
        }

        Write-Host ($instanceTable -join [Environment]::NewLine)
        $instanceRowCount = @(
            $instanceTable |
                Where-Object {
                    $_ -match "\S" -and
                    $_ -notmatch "^\s*Name\s" -and
                    $_ -notmatch "^\s*-+\s"
                }
        ).Count

        if ($instanceRowCount -lt 2 -and (Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 10
        }
    } while ($instanceRowCount -lt 2 -and (Get-Date) -lt $deadline)

    Write-Host "Final instance table (detected rows: $instanceRowCount):" -ForegroundColor Cyan
    Write-Host ($instanceTable -join [Environment]::NewLine)

    # 5. Call /info eight times with curl.exe and no cookies.
    Write-Host "Calling /info eight times..." -ForegroundColor Cyan
    for ($i = 1; $i -le 8; $i++) {
        Write-Host "Request ${i}:"
        curl.exe -s $BaseUrl/info
        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe failed while calling /info (request $i)."
        }
        Write-Host ""
    }

    # 6. Register an attendee using JSON produced by ConvertTo-Json.
    $registration = @{
        AttendeeName  = $AttendeeName
        AttendeeEmail = $AttendeeEmail
    }
    $registrationJson = $registration | ConvertTo-Json
    $registrationResponse = Invoke-RestMethod `
        -Method Post `
        -Uri $registrationUrl `
        -ContentType "application/json" `
        -Body $registrationJson
    Write-Host "Registration created: $($registrationResponse.id)" -ForegroundColor Green

    # 7. Get the event eight times and print the seatsTaken value.
    Write-Host "Reading seatsTaken eight times..." -ForegroundColor Cyan
    for ($i = 1; $i -le 8; $i++) {
        $event = Invoke-RestMethod -Method Get -Uri $eventUrl
        Write-Host "Request ${i}: seatsTaken = $($event.seatsTaken)"
    }
}
finally {
    # 8. Always scale back to one worker, enable affinity, and return to F1.
    # Nested finally blocks ensure later rollback commands are attempted if an
    # earlier rollback command fails.
    try {
        Write-Host "Scaling back to one worker..." -ForegroundColor Yellow
        az appservice plan update `
            --name $PlanName `
            --resource-group $ResourceGroup `
            --number-of-workers 1 `
            --output none
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to scale plan '$PlanName' back to one worker."
        }
    }
    finally {
        try {
            Write-Host "Enabling client affinity..." -ForegroundColor Yellow
            az webapp update `
                --name $AppName `
                --resource-group $ResourceGroup `
                --client-affinity-enabled true `
                --output none
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to enable client affinity for '$AppName'."
            }
        }
        finally {
            Write-Host "Returning the App Service plan to F1..." -ForegroundColor Yellow
            az appservice plan update `
                --name $PlanName `
                --resource-group $ResourceGroup `
                --sku F1 `
                --output none
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to return plan '$PlanName' to F1."
            }
        }
    }
}

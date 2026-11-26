// =============================================================
// Assignment 6 — Model solution: Campus Events environment
// (Assignment 4 main.bicep + monitoring + alerts as code)
//
//   App Service Plan + Web App
//   PostgreSQL Flexible Server (module)
//   Storage account, posters container (module)
//   Log Analytics + Application Insights (module)
//   Action Group + Http5xx alert (module, Exercise 1)
// =============================================================

@description('Your name in lowercase, no special characters — used in resource names')
param yourName string

@description('Owner tag value AND alert notification address (school email)')
param ownerEmail string

@description('Environment name — part of every resource name')
param environment string = 'dev'

param location string = resourceGroup().location

@allowed(['F1', 'B1'])
@description('App Service Plan SKU. F1 = free, B1 = paid (scale-out capable)')
param appServiceSku string = 'F1'

@secure()
@description('PostgreSQL admin password — the CLI prompts for this at deploy time')
param postgresAdminPassword string

// --- Naming convention (course standard) and shared tags ---

var planName           = 'plan-cloud26-${yourName}-${environment}'
var appName            = 'app-cloud26-${yourName}-${environment}'
var postgresServerName = 'pg-cloud26-${yourName}-${environment}'
var databaseName       = 'campusevents'
var postgresAdminLogin = 'campusadmin'
var storageAccountName = 'stcloud26${yourName}${environment}' // storage names: no hyphens!
var logAnalyticsName   = 'log-cloud26-${yourName}-${environment}'
var appInsightsName    = 'appi-cloud26-${yourName}-${environment}'
var actionGroupName    = 'ag-cloud26-${yourName}-email'

var tags = {
  Environment: environment
  Course: 'cloud26'
  Owner: ownerEmail
  ManagedBy: 'Bicep'
}

// --- PostgreSQL (module) ---

module postgres 'modules/postgres.bicep' = {
  name: 'postgresDeployment'
  params: {
    location: location
    serverName: postgresServerName
    databaseName: databaseName
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    tags: tags
  }
}

// --- Storage account (module) ---

module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: storageAccountName
    tags: tags
  }
}

// 'existing' reference for reading the account key (module outputs
// must not carry secrets); the web app declares dependsOn: [storage].
resource storageAccountRef 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// --- Monitoring (module) ---

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoringDeployment'
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    tags: tags
  }
}

// --- App Service Plan ---

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: planName
  location: location
  sku: {
    name: appServiceSku
  }
  kind: 'linux'
  properties: {
    reserved: true // required flag for Linux plans
  }
  tags: tags
}

// --- Web App ---

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appName
  location: location
  tags: tags
  dependsOn: [
    storage // the 'existing' reference reads keys — the account must exist first
  ]
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: appServiceSku != 'F1' // F1 does not support Always On
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          // Derived from the module output — cannot drift out of sync.
          name: 'ConnectionStrings__DefaultConnection'
          value: 'Host=${postgres.outputs.serverFqdn};Database=${databaseName};Username=${postgresAdminLogin};Password=${postgresAdminPassword};Ssl Mode=Require'
        }
        {
          // Storage key read at deploy time — derived, never hand-copied.
          name: 'ConnectionStrings__Storage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountRef.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
        }
        {
          // The App Insights SDK finds its backend through this —
          // same backing-service pattern as the database.
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: monitoring.outputs.connectionString
        }
      ]
    }
  }
}

// --- Alerts (module) — Exercise 1: alerts as code ---

module alerts 'modules/alerts.bicep' = {
  name: 'alertsDeployment'
  params: {
    alertEmail: ownerEmail
    webAppId: webApp.id
    actionGroupName: actionGroupName
    tags: tags
  }
}

// --- Outputs (read by scripts and pipelines) ---

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output postgresServerFqdn string = postgres.outputs.serverFqdn
output appInsightsName string = appInsightsName

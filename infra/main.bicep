@description('Your name in lowercase, no special characters — used in resource names')
param yourName string

@description('Owner tag value (school email)')
param ownerEmail string

@description('Environment name — part of every resource name')
param environment string = 'dev'

param location string = resourceGroup().location

@description('Location of the existing PostgreSQL server')
param postgresLocation string = 'northeurope'

@description('PostgreSQL server name')
param postgresServerName string

@allowed(['F1', 'B1'])
@description('App Service Plan SKU. F1 = free, B1 = paid (scale-out capable)')
param appServiceSku string = 'F1'

// --- Naming convention (course standard) and shared tags ---

var planName = 'plan-cloud26-${yourName}-${environment}'
var appName = 'app-cloud26-${yourName}-${environment}'

@secure()
@description('PostgreSQL admin password — read from POSTGRES_ADMIN_PASSWORD, never stored in a file')
param postgresAdminPassword string

var databaseName        = 'campusevents'
var postgresAdminLogin  = 'campusadmin'
var storageAccountName  = 'stcloud26${replace(yourName, '-', '')}${environment}' // letters + digits only, no hyphens, 3–24 characters total
var logAnalyticsName = 'log-cloud26-${yourName}-${environment}'
var appInsightsName  = 'appi-cloud26-${yourName}-${environment}'


var tags = {
  Environment: environment
  Course: 'cloud26'
  Owner: ownerEmail
  ManagedBy: 'Bicep'
  InfraPreview: 'enabled'
}
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
// --- PostgreSQL (module) ---

module postgres 'postgres.bicep' = {
  name: 'postgresDeployment'
  params: {
    location: postgresLocation
    serverName: postgresServerName
    databaseName: databaseName
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    tags: tags
  }
}
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoringDeployment'
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    tags: tags
  }
}

// --- Storage account + posters container (Assignment 3, section G) ---

module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: storageAccountName
    tags: tags
  }
}

resource storageAccountRef 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// --- Web App ---

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appName
  location: location
  tags: tags
  dependsOn: [
    storage
  ]
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: appServiceSku != 'F1' // F1 does not support Always On — deployment fails if set
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'ConnectionStrings__DefaultConnection'
          value: 'Host=${postgres.outputs.serverFqdn};Database=${databaseName};Username=${postgresAdminLogin};Password=${postgresAdminPassword};Ssl Mode=Require'
        }
        {
          name: 'ConnectionStrings__Storage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.outputs.accountName};AccountKey=${storageAccountRef.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: monitoring.outputs.connectionString
        }
      ]
    }
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output postgresServerFqdn string = postgres.outputs.serverFqdn
output storageAccountName string = storage.outputs.accountName
output blobEndpoint string = storage.outputs.blobEndpoint

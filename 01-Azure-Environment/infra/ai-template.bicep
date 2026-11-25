@description('The location for all resources.')
param location string = resourceGroup().location

@description('Environment identifier.')
param environmentName string = 'dev'

@description('Name of the Web App.')
param appName string = 'app-campusevents-${environmentName}'

@description('Name of the App Service Plan.')
param planName string = 'plan-campusevents-${environmentName}'

@description('Name of the PostgreSQL Flexible Server.')
param dbServerName string = 'psql-campusevents-${environmentName}'

@description('PostgreSQL administrator username.')
param adminUsername string = 'psqladmin'

@description('PostgreSQL administrator password.')
@secure()
param adminPassword string

@description('Common tags applied to all resources.')
var commonTags = {
  Application: 'cloud26'
  Environment: environmentName
  Course: 'cloud26'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  tags: commonTags
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  tags: commonTags
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: false // F1 Free tier does not support Always On
    }
  }
}

resource psqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: dbServerName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '16'
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    storage: {
      storageSizeGB: 32
    }
  }
}

resource psqlDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-03-01-preview' = {
  parent: psqlServer
  name: 'campusevents'
}

// Firewall rule allowing public access from any Azure service within Azure (0.0.0.0 to 0.0.0.0)
resource psqlFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = {
  parent: psqlServer
  name: 'AllowAllAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Injects the connection string as an app setting using standard .NET configuration naming conventions
resource webAppConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: webApp
  name: 'appsettings'
  properties: {
    ConnectionStrings__DefaultConnection: 'Server=${psqlServer.properties.fullyQualifiedDomainName};Database=campusevents;Port=5432;User Id=${adminUsername};Password=${adminPassword};Ssl Mode=Require;'
  }
}

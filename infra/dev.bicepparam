using 'main.bicep'

param yourName = readEnvironmentVariable('YOUR_NAME', 'aapo')
param ownerEmail = 'kontiainenape@gmail.com'
param environment = 'dev'
param location = 'swedencentral'
param postgresLocation = 'northeurope'
param postgresServerName = 'pg-cloud26-aapo-ne'
param appServiceSku = 'B1'

param postgresAdminPassword = readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD', '')

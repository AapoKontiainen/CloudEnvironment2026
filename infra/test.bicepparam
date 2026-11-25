using 'main.bicep'

param yourName = 'aapo'
param ownerEmail = 'kontiainenape@gmail.com'
param environment = 'test'
param location = 'swedencentral'
param postgresLocation = 'northeurope'
param postgresServerName = 'pg-cloud26-aapo-test'
param appServiceSku = 'B1'
param postgresAdminPassword = readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD', '')

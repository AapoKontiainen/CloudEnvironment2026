// Dev environment parameters.
// The password is NOT written here. main.bicep marks it @secure(),
// and this file only points at an environment variable.
// Set it in the same terminal before deploying:
//   $env:POSTGRES_ADMIN_PASSWORD = Read-Host "PostgreSQL admin password"
using 'main.bicep'

param yourName = 'matti'
param ownerEmail = 'matti.m@edu.xamk.fi'
param environment = 'dev'
param postgresAdminPassword = readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD')

metadata name = 'Shared Types'
metadata description = 'Shared type definitions for OPS Program Demo infrastructure.'

/* ─── Deployment Configuration ─── */

@export()
@description('Common deployment configuration shared across all modules.')
@sealed()
type DeploymentConfig = {
  @description('Resource name prefix for all resources.')
  prefix: string

  @description('Azure region for resource deployment.')
  location: string

  @description('Deployment environment.')
  environment: 'dev' | 'test' | 'prod'

  @description('Instance number to distinguish parallel deployments.')
  instanceNumber: string

  @description('Tags applied to all resources.')
  tags: object
}

/* ─── SQL Configuration ─── */

@export()
@description('SQL Server and database configuration.')
@sealed()
type SqlConfig = {
  @description('Azure AD administrator display name (user or group).')
  aadAdminLogin: string

  @description('Azure AD administrator object ID.')
  aadAdminObjectId: string

  @description('SQL Database SKU name.')
  skuName: 'Basic' | 'S0' | 'S1' | 'S2' | 'P1'
}

/* ─── App Service Configuration ─── */

@export()
@description('App Service Plan SKU configuration.')
@sealed()
type AppServicePlanConfig = {
  @description('SKU name for the App Service Plan.')
  skuName: 'F1' | 'B1' | 'B2' | 'S1' | 'S2' | 'P1v3'

  @description('Number of workers for the App Service Plan.')
  capacity: int
}

/* ─── Defaults ─── */

@export()
@description('Default deployment configuration values for development environment.')
var deploymentDefaults = {
  prefix: 'ops-demo'
  location: 'canadacentral'
  environment: 'dev'
  instanceNumber: '123'
  tags: {
    project: 'OPS-ProgramDemo'
    environment: 'dev'
    managedBy: 'bicep'
  }
}

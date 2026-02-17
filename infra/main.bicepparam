using 'main.bicep'

/* ─── Environment Configuration ─── */

var prefix = 'ops-demo'
var environment = 'dev'
var location = 'canadacentral'

/* ─── Common Parameters ─── */

param config = {
  prefix: prefix
  location: location
  environment: environment
  tags: {
    project: 'OPS-ProgramDemo'
    environment: environment
    managedBy: 'bicep'
    demo: 'DevDay2026'
  }
}

/* ─── App Service Parameters ─── */

param appServicePlanConfig = {
  skuName: 'B1'
  capacity: 1
}

/* ─── SQL Parameters ─── */

param sqlConfig = {
  aadAdminLogin: readEnvironmentVariable('SQL_AAD_ADMIN_LOGIN', 'sql-admins')
  aadAdminObjectId: readEnvironmentVariable('SQL_AAD_ADMIN_OBJECT_ID', '')
  skuName: 'Basic'
  isAllowAzureServicesEnabled: true
}

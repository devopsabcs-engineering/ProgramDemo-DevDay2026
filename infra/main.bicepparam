using 'main.bicep'

/* ─── Environment Configuration ─────────────────────────────────────────────
   instanceNumber and environment are passed as --parameters overrides by the
   deploy-infra workflow, so that a single bicepparam file serves all envs.
   The values here are the local/fallback defaults for ad-hoc runs.
──────────────────────────────────────────────────────────────────────────── */

param environment = 'dev'
param instanceNumber = '125'

/* ─── App Service Parameters ─── */

param appServicePlanConfig = {
  skuName: 'P1v3'
  capacity: 1
}

/* ─── SQL Parameters ─── */

param sqlConfig = {
  skuName: 'Basic'
}

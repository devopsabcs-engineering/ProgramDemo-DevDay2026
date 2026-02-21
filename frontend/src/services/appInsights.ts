import { ApplicationInsights } from '@microsoft/applicationinsights-web';

/**
 * Application Insights browser SDK initialization.
 *
 * The connection string is injected via:
 *   1. VITE_APPINSIGHTS_CONNECTION_STRING env var (build-time, from CI/CD)
 *   2. Falls back gracefully — telemetry is simply disabled when not set.
 *
 * Usage: import this module once in main.tsx; the `appInsights` instance
 * auto-tracks page views, ajax calls, exceptions, and performance metrics.
 */

const connectionString = import.meta.env.VITE_APPINSIGHTS_CONNECTION_STRING as
  | string
  | undefined;

let appInsights: ApplicationInsights | null = null;

if (connectionString) {
  appInsights = new ApplicationInsights({
    config: {
      connectionString,
      enableAutoRouteTracking: true,
      enableCorsCorrelation: true,
      enableRequestHeaderTracking: true,
      enableResponseHeaderTracking: true,
      disableFetchTracking: false,
      disableAjaxTracking: false,
      autoTrackPageVisitTime: true,
    },
  });

  appInsights.loadAppInsights();
  appInsights.context.application.ver =
    import.meta.env.VITE_APP_VERSION || '0.0.0';
}

export { appInsights };

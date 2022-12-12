//import React from 'react';
import { ApplicationInsights, DistributedTracingModes } from '@microsoft/applicationinsights-web';
import { ReactPlugin } from '@microsoft/applicationinsights-react-js'; //withAITracking
import { createBrowserHistory } from 'history';
const browserHistory = createBrowserHistory({ basename: '' });
const reactPlugin = new ReactPlugin();
const appInsights = new ApplicationInsights({
  config: {
    connectionString: window.AI_CONNECTION_STRING,
    extensions: [reactPlugin],
    distributedTracingMode: DistributedTracingModes.W3C,
    disableFetchTracking: false,
    enableCorsCorrelation: true,
    enableRequestHeaderTracking: true,
    enableResponseHeaderTracking: true,
    correlationHeaderExcludedDomains: ['myapp.azurewebsites.net', '*.queue.core.windows.net'],
    enableAutoRouteTracking: true,
    extensionConfig: {
      [reactPlugin.identifier]: { history: browserHistory },
    },
  },
});

if (appInsights && appInsights.snippet && appInsights.snippet.queue) {
  appInsights.snippet.queue.push(() => {
    appInsights.addTelemetryInitializer((envelope) => {
      if (envelope.tags) {
        envelope.tags['ai.cloud.role'] = 'RSA-UI';
      }
      if (envelope?.baseData?.uri == '/' || envelope?.baseData?.name == 'RSA') return false;

      //Ignore ResizeObserver error, it is triggered when debugging window is opened
      if (envelope?.data?.message == 'ErrorEvent: ResizeObserver loop limit exceeded') return false;

      return true;
    });
  });
}

appInsights.loadAppInsights();
//appInsights.trackPageView();

export { reactPlugin, appInsights };

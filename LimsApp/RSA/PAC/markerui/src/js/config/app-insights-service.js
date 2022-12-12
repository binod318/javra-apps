import { ApplicationInsights, DistributedTracingModes } from '@microsoft/applicationinsights-web';
import { ReactPlugin } from '@microsoft/applicationinsights-react-js'; //withAITracking
import { createBrowserHistory } from 'history';
const browserHistory = createBrowserHistory({ basename: '' });
const reactPlugin = new ReactPlugin();
const appInsights = new ApplicationInsights({
  config: {
    connectionString: window.services.AIConnectionString,
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

//add custom telemetry initializer. return false to skip telemetry logging
appInsights.snippet.queue.push(() => {
    appInsights.addTelemetryInitializer((envelope) => {
      if(envelope.tags) {
          envelope.tags['ai.cloud.role'] = 'PAC-UI';
      }

      //Ignore default pageview logging
      if (envelope.baseData.uri == '/' || envelope.baseData.name == 'ENZA :: PAC') return false;

      //Ignore ResizeObserver error, it is triggered when debugging window is opened
      if (envelope.data.message == 'ErrorEvent: ResizeObserver loop limit exceeded') return false;

    });
});

appInsights.loadAppInsights();

export { reactPlugin, appInsights };

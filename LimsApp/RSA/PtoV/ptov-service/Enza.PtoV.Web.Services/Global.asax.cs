using Enza.PtoV.Web.Services.Handlers;
using Microsoft.ApplicationInsights.Extensibility;
using System;
using System.Net;
using System.Web;
using System.Web.Http;

namespace Enza.PtoV.Web.Services
{
    public class WebApiApplication : HttpApplication
    {
        
        protected void Application_Start()
        {
            log4net.Config.XmlConfigurator.Configure();

            //Initialize Telemetry Processor
            var builder = TelemetryConfiguration.Active.DefaultTelemetrySink.TelemetryProcessorChainBuilder;
            builder.Use((next) => new SuccessfulDependencyFilter(next));
            builder.Build();
        }

        protected void Application_BeginRequest(object sender, EventArgs e)
        {
            HandlePreflightRequest(sender as HttpApplication);
        }


        public static void HandlePreflightRequest(HttpApplication app)
        {
            var request = app.Request;
            var response = app.Response;
            if (request.HttpMethod == "OPTIONS")
            {
                var origin = request.Headers.Get("Origin");
                if (!string.IsNullOrWhiteSpace(origin))
                {
                    response.AddHeader("Cache-Control", "no-cache");
                    response.AddHeader("Access-Control-Allow-Origin", origin);
                    response.AddHeader("Access-Control-Allow-Credentials", "true");
                    response.AddHeader("Access-Control-Allow-Methods", "GET,HEAD,POST,PUT,DELETE,CONNECT,OPTIONS,TRACE,PATCH");
                    response.AddHeader("Access-Control-Allow-Headers", "Authorization,enzauth,X-Version,origin,Content-Type,Accept");
                    response.AddHeader("Access-Control-Max-Age", int.MaxValue.ToString());
                    response.StatusCode = (int)HttpStatusCode.OK;
                    app.CompleteRequest();
                }
            }
        }
    }
}

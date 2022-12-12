using Enza.PAC.Common.Handlers;
using Enza.PAC.Web.Services.Core.Helpers;
using Microsoft.ApplicationInsights.Extensibility;
using System;
using System.Web;

namespace Enza.PAC.Web.Services
{
    public class WebApiApplication : System.Web.HttpApplication
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
            PreflightRequestHelper.HandlePreflightRequest(sender as HttpApplication);
        }
    }
}

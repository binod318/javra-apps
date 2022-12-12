using Enza.PAC.Common.Handlers;
using Enza.PAC.Web.Services.App_Start;
using Enza.PAC.Web.Services.Core.Handlers;
using Microsoft.ApplicationInsights.Extensibility;
using System.Configuration;
using System.Web.Http;
using System.Web.Http.Cors;
using System.Web.Http.ExceptionHandling;
using System.Web.Http.Hosting;

namespace Enza.PAC.Web.Services
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // Web API configuration and services
            ConfigureServices(config);

            // Web API routes
            config.MapHttpAttributeRoutes();

            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );
            
            var json = config.Formatters.JsonFormatter;
            json.SerializerSettings.DateFormatString = ConfigurationManager.AppSettings["DateFormat"];
        }

        static void ConfigureServices(HttpConfiguration config)
        {
            config.Services.Add(typeof(IExceptionLogger), new GlobalErrorLogger());
            config.Services.Replace(typeof(IExceptionHandler), new GlobalExceptionHandler());

            TelemetryConfiguration.Active.ConnectionString = ConfigurationManager.AppSettings["AIConnectionString"];
            TelemetryConfiguration.Active.TelemetryInitializers.Add(new CustomRequestResponseInitializer());

            config.Services.Replace(
                typeof(IHostBufferPolicySelector),
                new InputStreamAlwaysBufferedPolicySelector());
        }
    }
}

using System.Configuration;
using System.Web.Http;
using System.Web.Http.Cors;
using System.Web.Http.ExceptionHandling;
using System.Web.Http.Hosting;
using Enza.PtoV.Web.Services.Handlers;
using Newtonsoft.Json.Serialization;

namespace Enza.PtoV.Web.Services
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
                routeTemplate: "api/v1/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );

            config.Formatters.Remove(config.Formatters.XmlFormatter);

            var json = config.Formatters.JsonFormatter;
            json.SerializerSettings.DateFormatString = ConfigurationManager.AppSettings["App:DateFormat"];
            json.SerializerSettings.ContractResolver = new CamelCasePropertyNamesContractResolver();
        }

        private static void ConfigureServices(HttpConfiguration config)
        {
            config.Services.Add(typeof(IExceptionLogger), new GlobalErrorLogger());
            config.Services.Replace(typeof(IExceptionHandler), new GlobalExceptionHandler());

            config.Services.Replace(
                typeof(IHostBufferPolicySelector),
                new InputStreamAlwaysBufferedPolicySelector());
        }
    }
}

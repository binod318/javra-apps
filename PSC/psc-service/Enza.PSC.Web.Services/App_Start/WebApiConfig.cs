using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ExceptionHandling;
using System.Web.Http.Results;
using Enza.PSC.BusinessAccess;
using Enza.PSC.Common.Extensions;
using Enza.PSC.Common.Serialization;
using log4net;
using Unity;
using Unity.WebApi;
using System.Collections.Specialized;
using Enza.PSC.Common;
using Unity.Lifetime;
using Microsoft.ApplicationInsights.Extensibility;
using System.Configuration;
using Enza.PSC.Web.Services.Handlers;
using System.Web.Http.Hosting;

namespace Enza.PSC.Web.Services
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // Web API configuration and services
            RegisterComponents(config);
            RegisterServices(config);

            // Web API routes
            config.MapHttpAttributeRoutes();

            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );

            config.Formatters.Remove(config.Formatters.XmlFormatter);
            var formatter = config.Formatters.JsonFormatter;
            formatter.SerializerSettings.ContractResolver = new CamelCaseContractResolver();
        }

        private static void RegisterComponents(HttpConfiguration config)
        {
            var container = new UnityContainer();
            //register types here
            DependencyModule.Register(container);
            config.DependencyResolver = new UnityDependencyResolver(container);
        }

        private static void RegisterServices(HttpConfiguration config)
        {
            config.Services.Add(typeof(IExceptionLogger), new GlobalWebApiExceptionLogger());
            config.Services.Replace(typeof(IExceptionHandler), new GlobalExceptionHandler());

            TelemetryConfiguration.Active.ConnectionString = ConfigurationManager.AppSettings["AIConnectionString"];
            TelemetryConfiguration.Active.TelemetryInitializers.Add(new CustomRequestResponseInitializer());

            config.Services.Replace(
                typeof(IHostBufferPolicySelector),
                new InputStreamAlwaysBufferedPolicySelector());
        }
    }

    public class GlobalWebApiExceptionLogger : ExceptionLogger
    {
        private static readonly ILog logger =
            LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public override void Log(ExceptionLoggerContext context)
        {
            if (logger.IsErrorEnabled)
            {
                logger.Error(
                    $"Unhandled exception was thrown in {context.Request.Method} for request {context.Request.RequestUri}",
                    context.Exception);
            }
        }

        public override bool ShouldLog(ExceptionLoggerContext context)
        {
            return true;
        }
    }

    public class GlobalExceptionHandler : ExceptionHandler
    {
        public override bool ShouldHandle(ExceptionHandlerContext context)
        {
            return true;
        }

        public override void Handle(ExceptionHandlerContext context)
        {
            var exception = context.ExceptionContext.Exception.GetException();
            var error = new HttpError
            {
                {"message", exception.Message}
            };
            var response = context.Request.CreateErrorResponse(System.Net.HttpStatusCode.InternalServerError, error);
            response.ReasonPhrase = exception.GetType().FullName;
            context.Result = new ResponseMessageResult(response);
        }
    }
}

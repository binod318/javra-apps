using ENZA.LA.RSA.Services.Handlers;
using System.Web.Http;
using System.Web.Http.ExceptionHandling;

namespace ENZA.LA.RSA.Services
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            config.Services.Add(typeof(IExceptionLogger), new GlobalErrorLogger());

            // Web API configuration and services

            // Web API routes
            config.MapHttpAttributeRoutes();

            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );
            //config.MessageHandlers.Add(new EnzauthHandler());
        }
    }
}

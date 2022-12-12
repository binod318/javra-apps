using Enza.PtoV.Web.Services.App_Start;
using Enza.PtoV.Web.Services.Handlers;
using Enza.UTM.Web.Services;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Owin;
using Microsoft.Owin.Cors;
using Microsoft.Owin.Security.ActiveDirectory;
using Owin;
using System.Configuration;
using System.Threading.Tasks;
using System.Web.Cors;
using System.Web.Http;
/*
 * nuget packages
 * =================
 * Autofac.WebApi2.Owin //https://autofaccn.readthedocs.io/en/latest/integration/webapi.html#set-the-dependency-resolver
 * Microsoft.Owin
 * Microsoft.Owin.Host.SystemWeb
 * Microsoft.AspNet.WebApi.Owin 
 * Microsoft.Owin.Cors
 * Microsoft.Owin.Security.ActiveDirectory
 */

[assembly: OwinStartup(typeof(Startup))]
namespace Enza.PtoV.Web.Services.App_Start
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            var config = new HttpConfiguration();
            AutofacConfig.Configure(config, app);
            WebApiConfig.Register(config);
            SwaggerConfig.Register(config);

            ConfigureAuth(app);
            app.UseWebApi(config);

            TelemetryConfiguration.Active.ConnectionString = ConfigurationManager.AppSettings["AIConnectionString"];
            TelemetryConfiguration.Active.TelemetryInitializers.Add(new CustomRequestResponseInitializer());

        }

        private void ConfigureAuth(IAppBuilder app)
        {
            var corsPolicy = new CorsPolicy
            {
                AllowAnyMethod = true,
                AllowAnyHeader = true,
                AllowAnyOrigin = true,
                SupportsCredentials = true
            };
            var corsOptions = new CorsOptions
            {
                PolicyProvider = new CorsPolicyProvider
                {
                    PolicyResolver = context => Task.FromResult(corsPolicy)
                }
            };
            app.UseCors(corsOptions);
            app.UseWindowsAzureActiveDirectoryBearerAuthentication(new WindowsAzureActiveDirectoryBearerAuthenticationOptions
            {
                Tenant = ConfigurationManager.AppSettings["ida:tenant"],
                TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
                {
                    ValidAudience = ConfigurationManager.AppSettings["ida:audience"],
                    ValidateAudience = true,
                    ValidIssuer = ConfigurationManager.AppSettings["ida:issuer"],
                    ValidateIssuer = true,
                    ValidateLifetime = true
                }
            });
        }
    }
}
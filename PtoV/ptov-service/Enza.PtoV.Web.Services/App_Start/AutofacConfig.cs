using System.Reflection;
using System.Web.Http;
using Autofac;
using Autofac.Integration.WebApi;
using Enza.PtoV.BusinessAccess;
using Owin;

namespace Enza.PtoV.Web.Services
{
    public static class AutofacConfig
    {
        //public static void Configure(HttpConfiguration config)
        //{
        //    var builder = new ContainerBuilder();
        //    builder.RegisterApiControllers(Assembly.GetExecutingAssembly());

        //    //register other types
        //    builder.RegisterModule<AutofacModule>();
            
        //    var container = builder.Build();
        //    config.DependencyResolver = new AutofacWebApiDependencyResolver(container);
        //}

        public static void Configure(HttpConfiguration config, IAppBuilder app)
        {
            var builder = new ContainerBuilder();
            builder.RegisterApiControllers(Assembly.GetExecutingAssembly());

            //register other types
            builder.RegisterModule<AutofacModule>();
            var container = builder.Build();
            config.DependencyResolver = new AutofacWebApiDependencyResolver(container);
            app.UseAutofacMiddleware(container);
            app.UseAutofacWebApi(config);
        }
    }
}

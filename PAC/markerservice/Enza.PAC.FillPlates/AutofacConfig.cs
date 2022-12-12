using Autofac;
using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.BusinessAccess.Services;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.DataAccess.Data.Repositories;
using Enza.PAC.DataAccess.Databases;
using Enza.PAC.DataAccess.Interfaces;

namespace Enza.PAC.FillPlates
{
    public static class AutofacConfig
    {
        public static void Register(ContainerBuilder builder)
        {
            //Database
            builder.RegisterType<UserContext>().As<IUserContext>().InstancePerLifetimeScope();
            builder.RegisterType<PACDatabase>().As<IPACDatabase>()
                .WithParameter("nameOrConnectionString", "ConnectionString").InstancePerLifetimeScope();

            ////UEL
            //builder.RegisterType<UELService>().As<IUELService>().InstancePerLifetimeScope();

            //Repositories
            builder.RegisterType<TestRepository>().As<ITestRepository>().InstancePerLifetimeScope();

            //Services
            builder.RegisterType<TestService>().As<ITestService>().InstancePerLifetimeScope();
        }
    }
}

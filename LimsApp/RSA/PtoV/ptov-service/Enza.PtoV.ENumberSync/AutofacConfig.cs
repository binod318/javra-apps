using System.Reflection;
using Autofac;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.BusinessAccess.Services;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.DataAccess.Data.Repositories;
using Enza.PtoV.DataAccess.Databases;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Services.Interfaces;

namespace Enza.PtoV.ENumberSync
{
    public static class AutofacConfig
    {
        public static void Register(ContainerBuilder builder)
        {
            //Database
            builder.RegisterType<UserContext>().As<IUserContext>().InstancePerLifetimeScope();
            builder.RegisterType<SqlDatabase>().As<IDatabase>()
                .WithParameter("nameOrConnectionString", "ConnectionString").InstancePerLifetimeScope();

            builder.RegisterType<ENumberSyncRepository>().As<IENumberSyncRepository>().InstancePerLifetimeScope();
            builder.RegisterType<ENumberSyncService>().As<IENumberSyncService>().InstancePerLifetimeScope();
            builder.RegisterType<PhenomeServiceRespsitory>().As<IPhenomeServiceRespsitory>().InstancePerLifetimeScope();

            builder.RegisterType<EmailConfigRepository>().As<IEmailConfigRepository>().InstancePerLifetimeScope();
            builder.RegisterType<EmailConfigService>().As<IEmailConfigService>().InstancePerLifetimeScope();
            builder.RegisterType<EmailService>().As<IEmailService>().InstancePerLifetimeScope();
        }
    }
}
